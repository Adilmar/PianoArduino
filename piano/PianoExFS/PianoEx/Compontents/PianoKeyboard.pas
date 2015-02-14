{
  TPianoKeyborad v1.0
    Integration TPianoButton and TPanel
    TPianoButton come from TShapeBut (torry.com)

  Zizii Wan, 20050626, ShangHai, China
}

unit PianoKeyboard;

interface

uses
  Windows, SysUtils, Messages, Classes, Graphics, Controls, StdCtrls, ExtCtrls,
  Forms, Buttons, ActnList, ImgList, Math;

type
  TNote = record
    iChar: Integer;
    iNote: Integer;
  end;

const
  CLastKey = 37;
  CMaxKey = 222;
  CLastGroup = 9;

const // Default values
  CColor = clBlack;
  CFontColor = clWhite;
  CPianoGroup = 5;
  CPianoOctave = 3;
  CAutoWidth = True;
  CShowGroup = True;
  CKeyBoardTop = 12;
  CKeyBoardLeft = 12;

var
  Groups: array[0..CLastGroup - 1] of string = (
    'C2-B2',
    'C1-B1',
    'C-B',
    'c-b',
    'c1-b1',
    'c2-b2',
    'c3-b3',
    'c4-b4',
    'c5-b5');
  Notes: array[0..CLastKey - 1] of TNote = (
    (iChar: 90; iNote: 0),
    (iChar: 83; iNote: 1),
    (iChar: 88; iNote: 2),
    (iChar: 68; iNote: 3),
    (iChar: 67; iNote: 4),
    (iChar: 86; iNote: 5),
    (iChar: 71; iNote: 6),
    (iChar: 66; iNote: 7),
    (iChar: 72; iNote: 8),
    (iChar: 78; iNote: 9),
    (iChar: 74; iNote: 10),
    (iChar: 77; iNote: 11),
    (iChar: 188; iNote: 12),
    (iChar: 76; iNote: 13),
    (iChar: 190; iNote: 14),
    (iChar: 186; iNote: 15),
    (iChar: 191; iNote: 16),
    (iChar: 81; iNote: 12),
    (iChar: 50; iNote: 13),
    (iChar: 87; iNote: 14),
    (iChar: 51; iNote: 15),
    (iChar: 69; iNote: 16),
    (iChar: 82; iNote: 17),
    (iChar: 53; iNote: 18),
    (iChar: 84; iNote: 19),
    (iChar: 54; iNote: 20),
    (iChar: 89; iNote: 21),
    (iChar: 55; iNote: 22),
    (iChar: 85; iNote: 23),
    (iChar: 73; iNote: 24),
    (iChar: 57; iNote: 25),
    (iChar: 79; iNote: 26),
    (iChar: 48; iNote: 27),
    (iChar: 80; iNote: 28),
    (iChar: 219; iNote: 29),
    (iChar: 187; iNote: 30),
    (iChar: 221; iNote: 31)
    );

type
  TBevelWidth = 0..2;
  TPairArray = array[0..1] of Integer;

  TPianoButton = class(TGraphicControl)
  private
    FAutoSize: Boolean;
    FState: TButtonState;
    FBevelWidth: TBevelWidth;
    FBitmap: TBitmap;
    FBitmapUp: TBitmap;
    FBitmapDown: TBitmap;
    FHitTestMask: TBitmap;
    FPrevCursorSaved: Boolean;
    FPrevCursor: TCursor;
    FPrevShowHintSaved: Boolean;
    FPrevShowHint: Boolean;
    FPreciseShowHint: Boolean;
    procedure AdjustBounds;
    procedure AdjustSize(var W, H: Integer);
    function BevelColor(const AState: TButtonState; const TopLeft: Boolean): TColor;
    procedure BitmapChanged(Sender: TObject);
    procedure Create3DBitmap(Source: TBitmap; const AState: TButtonState; Target: TBitmap);
    procedure SetAutoSize(Value: Boolean);
    procedure SetBitmap(Value: TBitmap);
    procedure SetBitmapDown(Value: TBitmap);
    procedure SetBitmapUp(Value: TBitmap);
    procedure CMDialogChar(var Message: TCMDialogChar); message CM_DIALOGCHAR;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
    procedure CMTextChanged(var Message: TMessage); message CM_TEXTCHANGED;
    procedure CMSysColorChange(var Message: TMessage); message CM_SYSCOLORCHANGE;
    procedure CMHitTest(var Message: TCMHitTest); message CM_HITTEST;
    procedure SetBevelWidth(Value: TBevelWidth);
    procedure SetState(const Value: TButtonState);
  protected
    procedure DefineProperties(Filer: TFiler); override;
    procedure DrawButtonText(Canvas: TCanvas; const Caption: string; TextBounds: TRect; State: TButtonState); virtual;
    function GetPalette: HPALETTE; override;
    procedure Loaded; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure Paint; override;
    procedure ReadBitmapDownData(Stream: TStream); virtual;
    procedure ReadBitmapUpData(Stream: TStream); virtual;
    procedure WriteBitmapDownData(Stream: TStream); virtual;
    procedure WriteBitmapUpData(Stream: TStream); virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Click; override;
    procedure Invalidate; override;
    function PtInMask(const X, Y: Integer): Boolean; virtual;
    procedure SetBounds(ALeft, ATop, AWidth, AHeight: Integer); override;
    property BitmapUp: TBitmap read FBitmapUp;
    property BitmapDown: TBitmap read FBitmapDown;
    property State: TButtonState read FState write SetState;
  published
    property AutoSize: Boolean read FAutoSize write SetAutoSize default True;
    property BevelWidth: TBevelWidth read FBevelWidth write SetBevelWidth default 2;
    property Bitmap: TBitmap read FBitmap write SetBitmap;
    property Caption;
    property Enabled;
    property Font;
    property ParentFont;
    property ShowHint;
    property Visible;
    property OnClick;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
  end;

  TOnKeyboard = procedure(Event, data1, data2: Byte) of object;
  TPianoColor = (pcBlack, pcBlue, pcRed, pcGreen);

  { TPianoKeyboard }
  TPianoKeyboard = class(TCustomPanel)
  private
    FOwner: TWinControl;
    FPianoGroup: Integer;
    FPianoColor: TPianoColor;
    FPianoOctave: Byte;
    FGroupBox: TGroupBox;
    FPianoButton: array[0..11] of TPianoButton;
    FPianoBlackImgList: TImageList;
    FPianoWhiteImgList: TImageList;
    GrpsList, BtnsList, NotesList: TStringList;
    FKeyBoardLeft: Integer;
    FKeyBoardTop: Integer;
    FAutoWidth: Boolean;
    FShowGroup: Boolean;
    FOnKeyboard: TOnKeyboard;
    FGroupFontColor: TColor;
//    FOnPianoMouseDown: TMouseEvent;
//    FOnPianoMouseUp: TMouseEvent;
//    FOnPianoMouseMove: TMouseMoveEvent;
    procedure LoadBitmapFromResource;
    procedure InitPianoKeyboard;
    procedure BuildPianokeyBoard;
    procedure SetPianoColor(const Value: TPianoColor);
    procedure SetPianoOctave(const Value: Byte);
    procedure SetPianoGroup(const Value: Integer);
    procedure SetPianoGroupsMap;
    procedure SetKeyBoardLeft(const Value: Integer);
    procedure SetKeyBoardTop(const Value: Integer);
    procedure SetKeyBoardPos;
    procedure SetAutoWidth(const Value: Boolean);
    procedure SetShowGroup(const Value: Boolean);
    procedure ResetPianoButtons;
    procedure SetButtonColor(bFirst: Boolean; pcColor: TPianoColor; pbButton: TPianoButton);
    procedure SetButtonsColor(bFirst: Boolean; pcColor: TPianoColor);
    procedure SetGroupFontColor(const Value: TColor);
  protected
    procedure PianoMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure PianoMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure PianoMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure DoMidiEvent(Event, data1, data2: Byte; pcColor: TPianoColor);
    procedure DoPianoColor(iNote: Byte; pcColor: TPianoColor);
    procedure DoPianoShortCut(var Msg: TWMKey; var Handled: Boolean);
    procedure DoPianoKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure DoPianoKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
  published
    property GroupFontColor: TColor read FGroupFontColor write SetGroupFontColor;
    property PianoGroup: Integer read FPianoGroup write SetPianoGroup default CPianoGroup;
    property PianoColor: TPianoColor read FPianoColor write SetPianoColor default pcBlack;
    property PianoOctave: Byte read FPianoOctave write SetPianoOctave default CPianoOctave;
    property AutoWidth: Boolean read FAutoWidth write SetAutoWidth default CAutoWidth;
    property ShowGroup: Boolean read FShowGroup write SetShowGroup default CShowGroup;
    property KeyBoardTop: Integer read FKeyBoardTop write SetKeyBoardTop default CKeyBoardTop;
    property KeyBoardLeft: Integer read FKeyBoardLeft write SetKeyBoardLeft default CKeyBoardLeft;
    property OnKeyboard: TOnKeyboard read FOnKeyboard write FOnKeyboard;
//    property OnPianoMouseDown: TMouseEvent read FOnPianoMouseDown write FOnPianoMouseDown;
//    property OnPianoMouseMove: TMouseMoveEvent read FOnPianoMouseMove write FOnPianoMouseMove;
//    property OnPianoMouseUp: TMouseEvent read FOnPianoMouseUp write FOnPianoMouseUp;
    { inherited }
    property Anchors;
    property BevelInner;
    property BevelOuter;
    property BevelWidth;
    property Caption;
    property Color default CColor;
    property Enabled;
    property Font;
    property ParentFont;
    property PopupMenu;
    property ParentShowHint;
    property ShowHint;
    property Visible;
    property OnClick;
    property OnDblClick;
    property OnEnter;
    property OnExit;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;
  end;

procedure Register;

implementation

{$R *.RES}

function MakeMask(ColorBmp: TBitmap; TransparentColor: TColor): TBitmap;
var
  R: TRect;
  OldBkColor: TColorRef;
begin
  Result := TBitmap.Create;
  try
    Result.Monochrome := True;
    Result.Width := ColorBmp.Width;
    Result.Height := ColorBmp.Height;
    OldBkColor := SetBkColor(ColorBmp.Canvas.Handle, ColorToRGB(TransparentColor));
    R := Rect(0, 0, ColorBmp.Width, ColorBmp.Height);
    Result.Canvas.CopyMode := cmSrcCopy;
    Result.Canvas.CopyRect(R, ColorBmp.Canvas, R);
    SetBkColor(ColorBmp.Canvas.Handle, OldBkColor);
  except
    Result.Free;
    raise;
  end;
end;

function MakeBorder(Source, NewSource: TBitmap; const OffsetPts: array of TPairArray;
  TransparentColor: TColor): TBitmap;
var
  I, W, H: Integer;
  R, NewR: TRect;
  SmallMask, BigMask, NewSourceMask: TBitmap;
begin
  Result := TBitmap.Create;
  try
    W := Source.Width;
    H := Source.Height;
    R := Rect(0, 0, W, H);
    Result.Monochrome := True;
    Result.Width := W;
    Result.Height := H;
    SmallMask := MakeMask(Source, TransparentColor);
    NewSourceMask := MakeMask(NewSource, TransparentColor);
    BigMask := MakeMask(NewSourceMask, TransparentColor);
    try
      BigMask.Canvas.CopyMode := cmSrcCopy;
      BigMask.Canvas.CopyRect(R, NewSourceMask.Canvas, R);
      for I := Low(OffsetPts) to High(OffsetPts) do
      begin
        if (OffsetPts[I, 0] = 0) and (OffsetPts[I, 1] = 0) then
          Break;
        NewR := R;
        OffsetRect(NewR, OffsetPts[I, 0], OffsetPts[I, 1]);
        BigMask.Canvas.CopyMode := cmSrcAnd;
        BigMask.Canvas.CopyRect(NewR, SmallMask.Canvas, R);
      end;
      BigMask.Canvas.CopyMode := cmSrcCopy;
      with Result do
      begin
        Canvas.CopyMode := cmSrcCopy;
        Canvas.CopyRect(R, NewSourceMask.Canvas, R);
        Canvas.CopyMode := $00DD0228;
        Canvas.CopyRect(R, BigMask.Canvas, R);
        Canvas.CopyMode := cmSrcCopy;
      end;
    finally
      SmallMask.Free;
      NewSourceMask.Free;
      BigMask.Free;
    end;
  except
    Result.Free;
    raise;
  end;
end;

{ TPianoButton }

constructor TPianoButton.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  SetBounds(0, 0, 80, 80);
  ControlStyle := [csCaptureMouse, csOpaque];
  FAutoSize := True;
  FBitmap := TBitmap.Create;
  FBitmap.OnChange := BitmapChanged;
  FBitmapUp := TBitmap.Create;
  FBitmapDown := TBitmap.Create;
  FHitTestMask := nil;
  ParentFont := True;
  FPreciseShowHint := True;
  FState := bsUp;
end;

destructor TPianoButton.Destroy;
begin
  FBitmap.Free;
  FBitmapUp.Free;
  FBitmapDown.Free;
  FHitTestMask.Free;
  inherited Destroy;
end;

procedure TPianoButton.Paint;
var
  W, H: Integer;
  Composite, Mask, Overlay, CurrentBmp: TBitmap;
  R, NewR: TRect;
begin
  if csDesigning in ComponentState then
    with Canvas do
    begin
      Pen.Style := psDash;
      Brush.Style := bsClear;
      Rectangle(0, 0, Width, Height);
    end;

  if (csDesigning in ComponentState) or
    (FState in [bsDisabled, bsExclusive]) then
    FState := bsUp;

  if (FState = bsUp) then
    CurrentBmp := FBitmapUp else
    CurrentBmp := FBitmapDown;

  if not CurrentBmp.Empty then
  begin
    W := Width;
    H := Height;
    R := ClientRect;
    NewR := R;

    Composite := TBitmap.Create;
    Overlay := TBitmap.Create;
    try
      with Composite do
      begin
        Width := W;
        Height := H;
        Canvas.CopyMode := cmSrcCopy;
        Canvas.CopyRect(R, Self.Canvas, R);
      end;
      with Overlay do
      begin
        Width := W;
        Height := H;
        Canvas.CopyMode := cmSrcCopy;
        Canvas.Brush.Color := FBitmap.TransparentColor;
        Canvas.FillRect(R);
        if FState = bsDown then
          OffsetRect(NewR, 1, 1);
        Canvas.CopyRect(NewR, CurrentBmp.Canvas, R);
      end;
      Mask := MakeMask(Overlay, FBitmap.TransparentColor);
      try
        Composite.Canvas.CopyMode := cmSrcAnd;
        Composite.Canvas.CopyRect(R, Mask.Canvas, R);

        Overlay.Canvas.CopyMode := $00220326;
        Overlay.Canvas.CopyRect(R, Mask.Canvas, R);

        Composite.Canvas.CopyMode := cmSrcPaint;
        Composite.Canvas.CopyRect(R, Overlay.Canvas, R);

        Canvas.CopyMode := cmSrcCopy;
        Canvas.CopyRect(R, Composite.Canvas, R);
      finally
        Mask.Free;
      end;
    finally
      Composite.Free;
      Overlay.Free;
    end;
  end;
  if Length(Caption) > 0 then
  begin
    Canvas.Font := Self.Font;
    R := CLIENTRECT;
    DrawButtonText(Canvas, Caption, R, FState);
  end;
end;

function TPianoButton.PtInMask(const X, Y: Integer): Boolean;
begin
  Result := True;
  if FHitTestMask <> nil then
    Result := (FHitTestMask.Canvas.Pixels[X, Y] = clBlack);
end;

procedure TPianoButton.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  Clicked: Boolean;
begin
  inherited MouseDown(Button, Shift, X, Y);
  if (Button = mbLeft) and Enabled then
  begin
    Clicked := PtInMask(X, Y);
    if Clicked then
    begin
      FState := bsDown;
      Repaint;
    end;
  end;
end;

procedure TPianoButton.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  InMask: Boolean;
begin
  inherited MouseMove(Shift, X, Y);
  InMask := PtInMask(X, Y);
  if FPreciseShowHint and not InMask then
  begin
    if not FPrevShowHintSaved then
    begin
      ParentShowHint := False;
      FPrevShowHint := ShowHint;
      ShowHint := False;
      FPrevShowHintSaved := True;
    end;
  end else if not InMask then
  begin
    if not FPrevCursorSaved then
    begin
      FPrevCursor := Cursor;
      Cursor := crDefault;
      FPrevCursorSaved := True;
    end;
  end else
  begin
    if FPrevShowHintSaved then
    begin
      ShowHint := FPrevShowHint;
      FPrevShowHintSaved := False;
    end;
    if FPrevCursorSaved then
    begin
      Cursor := FPrevCursor;
      FPrevCursorSaved := False;
    end;
  end;
end;

procedure TPianoButton.MouseUp(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  DoClick: Boolean;
begin
  inherited MouseUp(Button, Shift, X, Y);
  DoClick := PtInMask(X, Y);
  if (FState = bsDown) then
  begin
    FState := bsUp;
    Repaint;
  end;
  if DoClick then Click;
end;

procedure TPianoButton.Click;
begin
  inherited Click;
end;

function TPianoButton.GetPalette: HPALETTE;
begin
  Result := FBitmap.Palette;
end;

procedure TPianoButton.SetBitmap(Value: TBitmap);
begin
  FBitmap.Assign(Value);
end;

procedure TPianoButton.SetBitmapUp(Value: TBitmap);
begin
  FBitmapUp.Assign(Value);
end;

procedure TPianoButton.SetBitmapDown(Value: TBitmap);
begin
  FBitmapDown.Assign(Value);
end;

procedure TPianoButton.BitmapChanged(Sender: TObject);
var
  OldCursor: TCursor;
  W, H: Integer;
begin
  AdjustBounds;
  if not ((csReading in ComponentState) or (csLoading in ComponentState)) then
  begin
    if FBitmap.Empty then
    begin
      SetBitmapUp(nil);
      SetBitmapDown(nil);
    end else
    begin
      W := FBitmap.Width;
      H := FBitmap.Height;
      OldCursor := Screen.Cursor;
      Screen.Cursor := crHourGlass;
      try
        if (FBitmapUp.Width <> W) or (FBitmapUp.Height <> H) or
          (FBitmapDown.Width <> W) or (FBitmapDown.Height <> H) then
        begin
          FBitmapUp.Width := W;
          FBitmapUp.Height := H;
          FBitmapDown.Width := W;
          FBitmapDown.Height := H;
        end;
        Create3DBitmap(FBitmap, bsUp, FBitmapUp);
        Create3DBitmap(FBitmap, bsDown, FBitmapDown);

        FHitTestMask.Free;
        FHitTestMask := MakeMask(FBitmapUp, FBitmap.TransparentColor);
      finally
        Screen.Cursor := OldCursor;
      end;
    end;
  end;
  Invalidate;
end;

procedure TPianoButton.CMDialogChar(var Message: TCMDialogChar);
begin
  with Message do
    if IsAccel(CharCode, Caption) and Enabled then
    begin
      Click;
      Result := 1;
    end else
      inherited;
end;

procedure TPianoButton.CMFontChanged(var Message: TMessage);
begin
  Invalidate;
end;

procedure TPianoButton.CMTextChanged(var Message: TMessage);
begin
  Invalidate;
end;

procedure TPianoButton.CMHitTest(var Message: TCMHitTest);
begin
  inherited;
  if PtInMask(Message.XPos, Message.YPos) then
    Message.Result := HTCLIENT
  else
    Message.Result := HTNOWHERE;
end;

procedure TPianoButton.CMSysColorChange(var Message: TMessage);
begin
  BitmapChanged(Self);
end;

function TPianoButton.BevelColor(const AState: TButtonState; const TopLeft: Boolean): TColor;
begin
  // clBtnHighlight
  // clBtnShadow
  if (AState = bsUp) then
  begin
    if TopLeft then
      Result := $FEFEFE else
      Result := -$FFFFF0;
  end else
  begin
    if TopLeft then
      Result := -$FFFFF0 else
      Result := $FEFEFE;
  end;
end;

procedure TPianoButton.Create3DBitmap(Source: TBitmap; const AState: TButtonState; Target: TBitmap);
type
  OutlineOffsetPts = array[1..3, 0..1, 0..12] of TPairArray;
const
  OutlinePts: OutlineOffsetPts = (
    (
    ((1, -1), (1, 0), (1, 1), (0, 1), (-1, 1), (0, 0), (0, 0), (0, 0), (0, 0), (0, 0), (0, 0), (0, 0), (0, 0)),
    ((-1, 0), (-1, -1), (0, -1), (0, 0), (0, 0), (0, 0), (0, 0), (0, 0), (0, 0), (0, 0), (0, 0), (0, 0), (0, 0))
    ), (
    ((2, -2), (2, -1), (2, 0), (2, 1), (2, 2), (1, 2), (0, 2), (-1, 2), (-2, 2), (0, 0), (0, 0), (0, 0), (0, 0)),
    ((-2, 1), (-2, 0), (-2, -1), (-2, -2), (-1, -2), (0, -2), (1, -2), (0, 0), (0, 0), (0, 0), (0, 0), (0, 0), (0, 0))
    ), (
    ((3, -3), (3, -2), (3, -1), (3, 0), (3, 1), (3, 2), (3, 3), (2, 3), (1, 3), (0, 3), (-1, 3), (-2, 3), (-3, 3)),
    ((-3, 2), (-3, 1), (-3, 0), (-3, -1), (-3, -2), (-3, -3), (-2, -3), (-1, -3), (0, -3), (1, -3), (2, -3), (0, 0), (0, 0)))
    );
var
  I, J, W, H, Outlines: Integer;
  R: TRect;
  OutlineMask, Overlay, NewSource: TBitmap;
begin
  if (Source = nil) or (Target = nil) then
    Exit;

  W := Source.Width;
  H := Source.Height;
  R := Rect(0, 0, W, H);

  Overlay := TBitmap.Create;
  NewSource := TBitmap.Create;
  try
    NewSource.Width := W;
    NewSource.Height := H;

    Target.Canvas.CopyMode := cmSrcCopy;
    Target.Canvas.CopyRect(R, Source.Canvas, R);

    Overlay.Width := W;
    Overlay.Height := H;

    Outlines := FBevelWidth;
    //Inc(Outlines);
    for I := 1 to Outlines do
    begin
      with NewSource.Canvas do
      begin
        CopyMode := cmSrcCopy;
        CopyRect(R, Target.Canvas, R);
      end;
      for J := 0 to 1 do
      begin
        if (AState = bsDown) and (I = Outlines) and (J = 0) then
          Continue;
        OutlineMask := MakeBorder(Source, NewSource, OutlinePts[I, J],
          FBitmap.TransparentColor);
        try
          with Overlay.Canvas do
          begin
            Brush.Color := BevelColor(AState, (J = 1));
            CopyMode := $0030032A; { PSna }
            CopyRect(R, OutlineMask.Canvas, R);
          end;
          with Target.Canvas do
          begin
            CopyMode := cmSrcAnd; { DSa }
            CopyRect(R, OutlineMask.Canvas, R);

            CopyMode := cmSrcPaint; { DSo }
            CopyRect(R, Overlay.Canvas, R);
            CopyMode := cmSrcCopy;
          end;
        finally
          OutlineMask.Free;
        end;
      end;
    end;
  finally
    Overlay.Free;
    NewSource.Free;
  end;
end;

procedure TPianoButton.DrawButtonText(Canvas: TCanvas; const Caption: string;
  TextBounds: TRect; State: TButtonState);
var
  CString: array[0..255] of Char;
begin
  StrPCopy(CString, Caption);
  Canvas.Brush.Style := bsClear;
  if State = bsDown then OffsetRect(TextBounds, 1, 1);
  DrawText(Canvas.Handle, CString, -1, TextBounds,
    DT_CENTER or DT_VCENTER or DT_SINGLELINE);
end;

procedure TPianoButton.Loaded;
var
  BigMask: TBitmap;
  R: TRect;
begin
  inherited Loaded;
  if (FBitmap <> nil) and (FBitmap.Width > 0) and (FBitmap.Height > 0) then
  begin
    FHitTestMask.Free;
    FHitTestMask := MakeMask(FBitmap, FBitmap.TransparentColor);
    BigMask := MakeMask(FBitmapUp, FBitmap.TransparentColor);
    try
      R := Rect(0, 0, FBitmap.Width, FBitmap.Height);
      FHitTestMask.Canvas.CopyMode := cmSrcAnd;
      FHitTestMask.Canvas.CopyRect(R, BigMask.Canvas, R);
    finally
      BigMask.Free;
    end;
  end;
end;

procedure TPianoButton.DefineProperties(Filer: TFiler);
begin
  inherited DefineProperties(Filer);
  Filer.DefineBinaryProperty('BitmapUp', ReadBitmapUpData, WriteBitmapUpData, not FBitmapUp.Empty);
  Filer.DefineBinaryProperty('BitmapDown', ReadBitmapDownData, WriteBitmapDownData, not FBitmapDown.Empty)
end;

procedure TPianoButton.ReadBitmapUpData(Stream: TStream);
begin
  FBitmapUp.LoadFromStream(Stream);
end;

procedure TPianoButton.WriteBitmapUpData(Stream: TStream);
begin
  FBitmapUp.SaveToStream(Stream);
end;

procedure TPianoButton.ReadBitmapDownData(Stream: TStream);
begin
  FBitmapDown.LoadFromStream(Stream);
end;

procedure TPianoButton.WriteBitmapDownData(Stream: TStream);
begin
  FBitmapDown.SaveToStream(Stream);
end;

procedure TPianoButton.AdjustBounds;
begin
  SetBounds(Left, Top, Width, Height);
end;

procedure TPianoButton.AdjustSize(var W, H: Integer);
begin
  if not (csReading in ComponentState) and FAutoSize and not FBitmap.Empty then
  begin
    W := FBitmap.Width;
    H := FBitmap.Height;
  end;
end;

procedure TPianoButton.SetAutoSize(Value: Boolean);
begin
  if FAutoSize <> Value then
  begin
    FAutoSize := Value;
    AdjustBounds;
  end;
end;

procedure TPianoButton.SetBounds(ALeft, ATop, AWidth, AHeight: Integer);
var
  W, H: Integer;
begin
  W := AWidth;
  H := AHeight;
  AdjustSize(W, H);
  inherited SetBounds(ALeft, ATop, W, H);
end;

procedure TPianoButton.Invalidate;
var
  R: TRect;
begin
  if (Visible or (csDesigning in ComponentState)) and
    (Parent <> nil) and Parent.HandleAllocated then
  begin
    R := BoundsRect;
    InvalidateRect(Parent.Handle, @R, True);
  end;
end;

procedure TPianoButton.SetBevelWidth(Value: TBevelWidth);
begin
  if Value > 2 then
    Value := 2;
  if Value <> FBevelWidth then
  begin
    FBevelWidth := Value;
    BitmapChanged(Self);
  end;
end;

procedure TPianoButton.SetState(const Value: TButtonState);
begin
  FState := Value;
  Repaint;
end;

{ TPianoKeyboard }

procedure TPianoKeyboard.LoadBitmapFromResource;
var
  i: Integer;
  FBitmap: TBitmap;
begin
  FBitmap := TBitmap.Create;
  try
    for i := 0 to 4 do
    begin
      //FPianoBlackImgList.ResourceLoad(rtBitmap, 'B' + IntToStr(i), clNone);
      FBitmap.LoadFromResourceName(HInstance, 'B' + IntToStr(i));
      FPianoBlackImgList.Add(FBitmap, FBitmap);
    end;
    for i := 0 to 24 do
    begin
      //FPianoWhiteImgList.ResourceLoad(rtBitmap, 'W' + IntToStr(i), clNone);
      FBitmap.LoadFromResourceName(HInstance, 'W' + IntToStr(i));
      FPianoWhiteImgList.Add(FBitmap, FBitmap);
    end;
  finally
    FBitmap.Free;
  end;
end;

procedure TPianoKeyboard.InitPianoKeyboard;
var
  i: integer;
begin
  LoadBitmapFromResource; // Load Resource File

  for i := 0 to 11 do
  begin
    FPianoButton[i] := TPianoButton.Create(Self);
    with FPianoButton[i] do
    begin
      Name := 'PianoButton' + IntToStr(i);
      Parent := Self;
      Tag := i;
      BorderStyle := bsNone;
      Top := FKeyBoardTop + 16;
      case i of
        0, 2, 4: // White Button 0,2,4
          begin
            Width := 24;
            Height := 108;
            Left := KeyBoardLeft + i * 10;
            BevelWidth := 1;
          end;
        5, 7, 9, 11: // White Button 5,7,9,11
          begin
            Width := 24;
            Height := 108;
            Left := KeyBoardLeft + 60 + (i - 5) * 10;
            BevelWidth := 1;
          end;
        1, 3: // Black Button 1,3
          begin
            Width := 18;
            Height := 77;
            Left := KeyBoardLeft + 11 + (i - 1) * 12;
            BevelWidth := 2;
          end;
        6, 8, 10: // Black Button 6,8,10
          begin
            Width := 18;
            Height := 77;
            Left := KeyBoardLeft + 71 + (i - 6) * 11;
            BevelWidth := 2;
          end;
      end;
    end;
    BtnsList.AddObject(IntToStr(i), FPianoButton[i]);
  end;

  FGroupBox := TGroupBox.Create(Self);
  with FGroupBox do
  begin
    Name := 'FGroupBox0';
    Parent := Self;
    Left := KeyBoardLeft + 5;
    Top := FKeyBoardTop;
    Width := 129;
    Height := 17;
    //Font := Self.Font;
    //Font.Color := clWhite;
    Visible := FShowGroup;
  end;
  GrpsList.AddObject('0', FGroupBox);
end;

procedure TPianoKeyboard.BuildPianokeyBoard;
var
  i, j, k: Integer;
  iGroupWidth: Integer;
  btnTemp: TPianoButton;
  grpTemp: TGroupBox;
begin
  Visible := False;

  iGroupWidth := 7 * (FPianoButton[2].Left - FPianoButton[0].Left);
  Width := FPianoButton[0].Left + FPianoGroup * iGroupWidth + FPianoButton[0].Left;
  SetAutoWidth(FAutoWidth); // Auto Size Form
  // Rebuild it.
  for j := 12 to BtnsList.Count - 1 do
  begin
    BtnsList.Objects[j].Free;
  end;
  BtnsList.Clear;

  for j := 0 to 11 do
  begin
    BtnsList.AddObject(IntToStr(j), FPianoButton[j]);
  end;

  // Build more keys
  for i := 1 to FPianoGroup - 1 do
  begin
    for j := 0 to 11 do
    begin
      k := 12 * i + j;
      btnTemp := TPianoButton.Create(Self);
      with btnTemp do
      begin
        Parent := Self;
        Name := 'FPianoButton' + IntToStr(k);
        Tag := k;
        // Looks
        BevelWidth := TPianoButton(BtnsList.Objects[j]).BevelWidth;
        // Position
        Top := TPianoButton(BtnsList.Objects[j]).Top;
        Left := TPianoButton(BtnsList.Objects[j]).Left + i * iGroupWidth;
      end;
      // Add to Object list
      BtnsList.AddObject(IntToStr(k), btnTemp);
    end;
  end;

  // Set button events
  for i := 0 to BtnsList.Count - 1 do
  begin
    btnTemp := TPianoButton(BtnsList.Objects[i]);
    with btnTemp do
    begin
      OnMouseDown := PianoMouseDown;
      OnMouseMove := PianoMouseMove;
      OnMouseUp := PianoMouseUp;
    end;
  end;
  SetButtonsColor(True, FPianoColor); // Set Buttons Bitmap

  // Rebuild it.
  for i := 1 to GrpsList.Count - 1 do
  begin
    GrpsList.Objects[i].Free;
  end;
  GrpsList.Clear;

  GrpsList.AddObject('0', FGroupBox);
  // Build more groups
  for i := 1 to FPianoGroup - 1 do
  begin
    grpTemp := TGroupBox.Create(Self);
    with grpTemp do
    begin
      Parent := Self;
      Name := 'FGroupBox' + IntToStr(i);
      Top := FGroupBox.Top;
      Left := FGroupBox.Left + i * iGroupWidth;
      Height := FGroupBox.Height;
      Width := FGroupBox.Width;
      Visible := FShowGroup;
    end;
    // Add to object list
    GrpsList.AddObject(IntToStr(i), grpTemp);
  end;
  SetGroupFontColor(FGroupFontColor);
  SetPianoGroupsMap; // Set Groups Caption and visible

  Visible := True;

  // Build Keys Map
  for i := 0 to CMaxKey do
  begin
    NotesList.Add(#0);
  end;
  for i := 0 to CLastKey - 1 do
  begin
    NotesList.Strings[Notes[i].iChar] := IntToStr(Notes[i].iNote);
  end;
end;

procedure TPianoKeyboard.SetButtonColor(bFirst: Boolean; pcColor: TPianoColor; pbButton: TPianoButton);
var
  ind: integer;
begin
  ind := Integer(pcColor) + 1;
  case pbButton.Tag mod 12 of
    0, 5:
      begin
        if bFirst then
          pbButton.Bitmap.LoadFromResourceName(HInstance, 'W0');
        FPianoWhiteImgList.GetBitmap(5 * ind + 0, pbButton.BitmapDown);
      end;
    2:
      begin
        if bFirst then
          pbButton.Bitmap.LoadFromResourceName(HInstance, 'W1');
        FPianoWhiteImgList.GetBitmap(5 * ind + 1, pbButton.BitmapDown);
      end;
    4, 11:
      begin
        if bFirst then
          pbButton.Bitmap.LoadFromResourceName(HInstance, 'W2');
        FPianoWhiteImgList.GetBitmap(5 * ind + 2, pbButton.BitmapDown);
      end;
    7:
      begin
        if bFirst then
          pbButton.Bitmap.LoadFromResourceName(HInstance, 'W3');
        FPianoWhiteImgList.GetBitmap(5 * ind + 3, pbButton.BitmapDown);
      end;
    9:
      begin
        if bFirst then
          pbButton.Bitmap.LoadFromResourceName(HInstance, 'W4');
        FPianoWhiteImgList.GetBitmap(5 * ind + 4, pbButton.BitmapDown);
      end;
    1, 3, 6, 8, 10:
      begin
        if bFirst then
          pbButton.Bitmap.LoadFromResourceName(HInstance, 'B0');
        FPianoBlackImgList.GetBitmap(ind + 0, pbButton.BitmapDown);
      end;
  end;
end;

procedure TPianoKeyboard.SetButtonsColor(bFirst: Boolean; pcColor: TPianoColor);
var
  i: integer;
begin
  for i := 0 to BtnsList.Count - 1 do
  begin
    SetButtonColor(bFirst, pcColor, TPianoButton(BtnsList.Objects[i]));
  end;
end;

procedure TPianoKeyboard.SetGroupFontColor(const Value: TColor);
var
  i: Integer;
begin
  FGroupFontColor := Value;
  for i := 0 to GrpsList.Count - 1 do
  begin
    TGroupBox(GrpsList.Objects[i]).Font.Color := FGroupFontColor;
  end;
end;

procedure TPianoKeyboard.SetPianoGroupsMap;
var
  i: Integer;
begin
  // Build Groups Map
  for i := 0 to GrpsList.Count - 1 do
  begin
    if (i + FPianoOctave) < CLastGroup then
    begin
      TGroupBox(GrpsList.Objects[i]).Visible := FShowGroup;
      TGroupBox(GrpsList.Objects[i]).Caption := Groups[i + FPianoOctave];
    end else
    begin
      TGroupBox(GrpsList.Objects[i]).Visible := False;
    end;
  end;
end;

constructor TPianoKeyboard.Create(AOwner: TComponent);
begin
  inherited;
  Height := 145;
  Width := 174;
  Color := CColor;
  FGroupFontColor := CFontColor;
  FKeyBoardTop := CKeyBoardTop;
  FKeyBoardLeft := CKeyBoardLeft;
  FPianoGroup := CPianoGroup;
  FPianoOctave := CPianoOctave;
  FPianoColor := pcGreen;
  FAutoWidth := CAutoWidth;
  FShowGroup := CShowGroup;

  FOwner := (AOwner as TWinControl);

  FPianoBlackImgList := TImageList.CreateSize(13, 73);
  FPianoWhiteImgList := TImageList.CreateSize(20, 104);
  GrpsList := TStringList.Create; // Hold Groups description
  BtnsList := TStringList.Create; // Hold Buttons for Piano
  NotesList := TStringList.Create; // Hold Keys Map of note

  InitPianoKeyboard;
  BuildPianokeyBoard;
end;

destructor TPianoKeyboard.Destroy;
begin
  FPianoBlackImgList := nil;
  FPianoWhiteImgList := nil;
  FreeAndNil(GrpsList);
  FreeAndNil(BtnsList);
  FreeAndNil(NotesList);
  inherited;
end;

procedure TPianoKeyboard.SetPianoGroup(const Value: Integer);
begin
  FPianoGroup := Value;
  BuildPianokeyBoard;
end;

procedure TPianoKeyboard.SetPianoColor(const Value: TPianoColor);
begin
  FPianoColor := Value;
  ResetPianoButtons;
  SetButtonsColor(False, FPianoColor);
end;

procedure TPianoKeyboard.SetPianoOctave(const Value: Byte);
begin
  FPianoOctave := Value;
  ResetPianoButtons;
  SetPianoGroupsMap;
end;

procedure TPianoKeyboard.SetKeyBoardLeft(const Value: Integer);
begin
  FKeyBoardLeft := Value;
  SetKeyBoardPos;
end;

procedure TPianoKeyboard.SetKeyBoardTop(const Value: Integer);
begin
  FKeyBoardTop := Value;
  SetKeyBoardPos;
end;

procedure TPianoKeyboard.SetKeyBoardPos;
var
  i: Integer;
  iLeft, iTop: Integer;
begin
  iLeft := FKeyBoardLeft - (FGroupBox.Left - 5);
  iTop := FKeyBoardTop - FGroupBox.Top;
  for i := 0 to BtnsList.Count - 1 do
  begin
    TPianoButton(BtnsList.Objects[i]).Left := TPianoButton(BtnsList.Objects[i]).Left + iLeft;
    TPianoButton(BtnsList.Objects[i]).Top := TPianoButton(BtnsList.Objects[i]).Top + iTop;
  end;
  for i := 0 to GrpsList.Count - 1 do
  begin
    TGroupBox(GrpsList.Objects[i]).Left := TGroupBox(GrpsList.Objects[i]).Left + iLeft;
    TGroupBox(GrpsList.Objects[i]).Top := TGroupBox(GrpsList.Objects[i]).Top + iTop;
  end;
end;

procedure TPianoKeyboard.SetAutoWidth(const Value: Boolean);
begin
  FAutoWidth := Value;
  if FAutoWidth then
    FOwner.Width := Width + 2 * Left;
end;

procedure TPianoKeyboard.SetShowGroup(const Value: Boolean);
begin
  FShowGroup := Value;
  SetPianoGroupsMap;
end;

procedure TPianoKeyboard.ResetPianoButtons;
var
  i: integer;
begin
  for i := 0 to BtnsList.Count - 1 do
  begin
    //SetButtonColor(False, FPianoColor, TPianoButton(BtnsList.Objects[i]));
    if TPianoButton(BtnsList.Objects[i]).State <> bsUP then
    begin
      TPianoButton(BtnsList.Objects[i]).State := bsUp;
    end;
  end;
end;

procedure TPianoKeyboard.DoMidiEvent(Event, data1, data2: Byte; pcColor: TPianoColor);
var
  iButton: Integer;
begin
  iButton := data1 - FPianoOctave * 12;
  case (event and $F0) of
    $90: // Note On
      begin
        if (iButton < BtnsList.Count) and (iButton >= 0) then
        begin
          if data2 <> 0 then
          begin
            if Integer(pcColor) <> -1 then
              DoPianoColor(iButton, pcColor);
            TPianoButton(BtnsList.Objects[iButton]).State := bsDown
          end else
          begin
            TPianoButton(BtnsList.Objects[iButton]).State := bsUp;
          end;
        end;
      end;
    $80: // Note Off
      begin
        if (iButton < BtnsList.Count) and (iButton >= 0) then
        begin
          TPianoButton(BtnsList.Objects[iButton]).State := bsUp;
        end;
      end;
    $B0: // Control change
      begin
        if data1 = $7E then
        begin
          ResetPianoButtons;
        end;
      end;
    $7B: // All notes off
      begin
        ResetPianoButtons;
      end;
  end;
end;

procedure SetMouseOctave(var iOctave: Integer; Shift: TShiftState);
begin
  if ssShift in Shift then Inc(iOctave);
  if ssCtrl in Shift then Dec(iOctave);
end;

procedure TPianoKeyboard.PianoMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  iOctave, iNote, iSpeed: Integer;
  ABtn: TPianoButton;
begin
//  if Assigned(FOnPianoMouseDown) then
//    FOnPianoMouseDown(Sender, Button, Shift, X, Y);

  if not (Sender is TPianoButton) then Exit;
  ABtn := Sender as TPianoButton;

  iOctave := FPianoOctave + ABtn.Tag div 12;
  SetMouseOctave(iOctave, Shift);
  iNote := ABtn.Tag mod 12;
  iSpeed := 64;
  ABtn.State := bsDown;

  if Assigned(FOnKeyboard) then
    FOnKeyboard($90, iOctave * 12 + iNote, iSpeed);
end;

procedure TPianoKeyboard.PianoMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
begin
//  if Assigned(FOnPianoMouseMove) then
//    FOnPianoMouseMove(Sender, Shift, X, Y);
end;

procedure TPianoKeyboard.PianoMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  iOctave, iNote, iSpeed: Integer;
  ABtn: TPianoButton;
begin
//  if Assigned(FOnPianoMouseUp) then
//    FOnPianoMouseUp(Sender, Button, Shift, X, Y);

  if not (Sender is TPianoButton) then Exit;
  ABtn := Sender as TPianoButton;

  iOctave := FPianoOctave + ABtn.Tag div 12;
  SetMouseOctave(iOctave, Shift);
  iNote := ABtn.Tag mod 12;
  iSpeed := 64;
  ABtn.State := bsUp;

  if Assigned(FOnKeyboard) then
    FOnKeyboard($80, iOctave * 12 + iNote, iSpeed);
end;

procedure TPianoKeyboard.DoPianoColor(iNote: Byte; pcColor: TPianoColor);
begin
  if iNote >= BtnsList.Count then Exit;
  SetButtonColor(False, pcColor, TPianoButton(BtnsList.Objects[iNote]));
end;

procedure TPianoKeyboard.DoPianoShortCut(var Msg: TWMKey;
  var Handled: Boolean);
const
  KD31 = $40000000;
begin
  case Msg.Msg of
    CN_KEYDOWN:
      begin
        // this code is very useful to hanlde the system keydelay and keyrepeat.
        if (Msg.KeyData and KD31) <> 0 then
          Handled := True;
      end;
  end;
end;

procedure TPianoKeyboard.DoPianoKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if NotesList[Key] = #0 then Exit;
  PianoMouseDown(BtnsList.Objects[StrToInt(NotesList.Strings[Key])], mbLeft, Shift, -1, -1);
end;

procedure TPianoKeyboard.DoPianoKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if NotesList[Key] = #0 then Exit;
  PianoMouseUp(BtnsList.Objects[StrToInt(NotesList.Strings[Key])], mbLeft, Shift, -1, -1);
end;

procedure Register;
begin
  RegisterComponents('Piano Suite', [TPianoKeyboard]);
end;

end.

