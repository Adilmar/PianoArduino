{
  TPianoChannels v1.0
    Integration TProgress and TCheckBox

  Zizii Wan, 20050722, ShangHai, China
}

unit PianoChannels;

interface

uses
  Windows, SysUtils, Messages, Classes, Graphics, Controls, StdCtrls, ExtCtrls,
  ComCtrls, Forms, Math;

const // Default values
  CChannelSpace = 12;
  CChannelHeight = 66;
  CChannelLeft = 6;
  CChannelTop = 8;

type
  TPianoChannels = class;

  { TPianoChannels }
  TPianoChannels = class(TCustomPanel)
  private
    FOwner: TWinControl;
    FChannelList: TStringList;
    FChannelHeight: Integer;
    FChannelSpace: Integer;
    FChannelLeft: Integer;
    FChannelTop: Integer;
    FOnChannelClick: TNotifyEvent;
    procedure SetChannelHeight(const Value: Integer);
    procedure SetChannelLeft(const Value: Integer);
    procedure SetChannelTop(const Value: Integer);
    procedure SetChannelSpace(const Value: Integer);
  protected
    procedure BuildChannels;
    procedure PianoChannelClick(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function GetChannelActive(Channel: Byte): Boolean;
    procedure DoChannelBar(Channel: Byte; Value: Integer);
    procedure DoChannelBox(Channel: Byte; Value: Boolean);
    procedure ResetChannel(bBox: Boolean);
  published
    property ChannelTop: Integer read FChannelTop write SetChannelTop default CChannelTop;
    property ChannelLeft: Integer read FChannelLeft write SetChannelLeft default CChannelLeft;
    property ChannelSpace: Integer read FChannelSpace write SetChannelSpace default CChannelSpace;
    property ChannelHeight: Integer read FChannelHeight write SetChannelHeight default CChannelHeight;
    property OnChannelClick: TNotifyEvent read FOnChannelClick write FOnChannelClick;
    { inherited }
    property Align;
    property Anchors;
    property BevelInner;
    property BevelOuter;
    property BevelWidth;
    property Caption;
    property Color;
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

procedure TPianoChannels.BuildChannels;
var
  i, iLeft: integer;
  tmpBar: TProgressBar;
  tmpBox: TCheckBox;
begin
  for i := FChannelList.Count - 1 downto 0 do
  begin
    FChannelList.Objects[i].Free;
  end;
  FChannelList.Clear;

  for i := 0 to 15 do
  begin
    iLeft := FChannelLeft + i * (FChannelLeft + FChannelSpace);
    tmpBar := TProgressBar.Create(Self);
    with tmpBar do
    begin
      Name := 'pbChannel' + IntToStr(i);
      Parent := Self;
      Left := iLeft;
      Top := FChannelTop;
      Width := 12;
      Height := FChannelHeight;
      Orientation := pbVertical;
      Tag := i;
    end;
    FChannelList.AddObject(IntToStr(i), tmpBar);
  end;
  for i := 0 to 15 do
  begin
    iLeft := FChannelLeft + i * (FChannelLeft + FChannelSpace);
    tmpBox := TCheckBox.Create(Self);
    with tmpBox do
    begin
      Name := 'chkChannel' + IntToStr(i);
      Parent := Self;
      Left := iLeft - 1;
      Width := 32;
      Height := 17;
      Top := FChannelTop + FChannelHeight + 5 + (i mod 2) * Height;
      Caption := IntToStr(i);
      Tag := i;
      OnClick := PianoChannelClick;
    end;
    FChannelList.AddObject(IntToStr(16 + i), tmpBox)
  end;
  ResetChannel(True);
end;

constructor TPianoChannels.Create(AOwner: TComponent);
begin
  inherited;
  //Align := alClient;
  Caption := '';
  FOwner := (AOwner as TWinControl);
  FChannelList := TStringList.Create;

  FChannelHeight := CChannelHeight;
  FChannelLeft := CChannelLeft;
  FChannelTop := CChannelTop;
  FChannelSpace := CChannelSpace;

  BuildChannels;
end;

destructor TPianoChannels.Destroy;
begin
  FreeAndNil(FChannelList);
  inherited;
end;

procedure TPianoChannels.SetChannelHeight(const Value: Integer);
begin
  FChannelHeight := Value;
  BuildChannels;
end;

procedure TPianoChannels.SetChannelLeft(const Value: Integer);
begin
  FChannelLeft := Value;
  BuildChannels;
end;

procedure TPianoChannels.SetChannelTop(const Value: Integer);
begin
  FChannelTop := Value;
  BuildChannels;
end;

procedure TPianoChannels.SetChannelSpace(const Value: Integer);
begin
  FChannelSpace := Value;
  BuildChannels;
end;

function TPianoChannels.GetChannelActive(Channel: Byte): Boolean;
begin
  if Channel > 15 then
    raise Exception.Create('Channel boundary out error!');
  Result := TCheckBox(FChannelList.Objects[16 + Channel]).Checked;
end;

procedure TPianoChannels.DoChannelBar(Channel: Byte; Value: Integer);
begin
  if Value > 100 then Value := 100;
  TProgressBar(FChannelList.Objects[Channel]).Position := Value;
end;

procedure TPianoChannels.DoChannelBox(Channel: Byte; Value: Boolean);
begin
  TCheckBox(FChannelList.Objects[16 + Channel]).Enabled := True;
  TCheckBox(FChannelList.Objects[16 + Channel]).Checked := Value;
end;

procedure TPianoChannels.ResetChannel(bBox: Boolean);
var
  i: Integer;
begin
  for i := 0 to 15 do
  begin
    with TProgressBar(FChannelList.Objects[i]) do
    begin
      Position := 0;
    end;
  end;
  if not bBox then Exit;
  for i := 0 to 15 do
  begin
    with TCheckBox(FChannelList.Objects[16 + i]) do
    begin
      Checked := True;
      Enabled := False;
    end;
  end;
end;

procedure TPianoChannels.PianoChannelClick(Sender: TObject);
begin
  if Assigned(FOnChannelClick) then
    FOnChannelClick(Sender);
end;

procedure Register;
begin
  RegisterComponents('Piano Suite', [TPianoChannels]);
end;

end.

