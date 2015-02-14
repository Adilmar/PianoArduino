{
  TPianoTracks v1.0
    Integration 3 TCheckListBox

  Zizii Wan, 20050724, ShangHai, China
}

unit PianoTracks;

interface

uses
  Windows, SysUtils, Messages, Classes, Graphics, Controls, StdCtrls, ExtCtrls,
  ComCtrls, CheckLst, Forms, Math;

const
  CLeftCaption = 'Left';
  CRightCaption = 'Right';
                                   
type
  TTrackHand = (thUnknow, thRight, thLeft);
  // this is same order with FPianoTracks[i]

  { TTrackInfo }
  TTrackInfo = class
  private
    FTrackName: string;
    FTrackIndex: Byte;
    FTrackActive: Boolean;
    FTrackHand: TTrackHand;
    procedure SetTrackActive(const Value: Boolean);
    procedure SetTrackHand(const Value: TTrackHand);
    procedure SetTrackIndex(const Value: Byte);
    procedure SetTrackName(const Value: string);
  published
    property TrackName: string read FTrackName write SetTrackName;
    property TrackIndex: Byte read FTrackIndex write SetTrackIndex;
    property TrackActive: Boolean read FTrackActive write SetTrackActive;
    property TrackHand: TTrackHand read FTrackHand write SetTrackHand;
  end;

  { TPianoTracks }
  TPianoTracks = class(TCustomPanel)
  private
    FOwner: TWinControl;
    FPanel: TPanel;
    FLeftGroupBox: TGroupBox;
    FRightGroupBox: TGroupBox;
    FPianoTracks: array[0..2] of TCheckListBox; // Objects hold integer of trackindex
    FTrackList: TStringList; // Objects hold object of trackinfo
    FOnTrackClick: TNotifyEvent;
    FOnTrackMove: TNotifyEvent;
    FRightCaption: TCaption;
    FLeftCaption: TCaption;
    procedure PianoResize(Sender: TObject);
    procedure PianoTrackClick(Sender: TObject);
    procedure PianoDragOver(Sender, Source: TObject; X, Y: Integer;
      State: TDragState; var Accept: Boolean);
    procedure PianoDragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure SetLeftCaption(const Value: TCaption);
    procedure SetRightCaption(const Value: TCaption);
  protected
    procedure BuildTracks;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure AddTrack(Info: TTrackInfo);
    procedure ClearTracks;
    procedure SetTrackActive(Track: Byte; Value: Boolean);
    function GetTrackActive(Track: Byte): Boolean;
    procedure SetTrackHand(Track: Byte; Value: TTrackHand);
    function GetTrackHand(Track: Byte): TTrackHand;
  published
    property LeftCaption: TCaption read FLeftCaption write SetLeftCaption;
    property RightCaption: TCaption read FRightCaption write SetRightCaption;
    property OnTrackClick: TNotifyEvent read FOnTrackClick write FOnTrackClick;
    property OnTrackMove: TNotifyEvent read FOnTrackMove write FOnTrackMove;
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

{ TTrackInfo }

procedure TTrackInfo.SetTrackActive(const Value: Boolean);
begin
  FTrackActive := Value;
end;

procedure TTrackInfo.SetTrackHand(const Value: TTrackHand);
begin
  FTrackHand := Value;
end;

procedure TTrackInfo.SetTrackIndex(const Value: Byte);
begin
  FTrackIndex := Value;
end;

procedure TTrackInfo.SetTrackName(const Value: string);
begin
  FTrackName := Value;
end;

{ TPianoTracks}

procedure TPianoTracks.BuildTracks;
var
  i: integer;
  Splitter1: TSplitter;
begin
  for i := 0 to 2 do
    FPianoTracks[i] := TCheckListBox.Create(Self);
  FPanel := TPanel.Create(Self);
  Splitter1 := TSplitter.Create(Self);
  FRightGroupBox := TGroupBox.Create(Self);
  FLeftGroupBox := TGroupBox.Create(Self);
  with FPanel do
  begin
    Name := 'Panel1';
    Parent := Self;
    Align := alRight;
    BevelOuter := bvNone;
  end;
  with FRightGroupBox do
  begin
    Name := 'grpRight';
    Parent := FPanel;
    Align := alTop;
    Caption := FRightCaption;
  end;
  with FLeftGroupBox do
  begin
    Name := 'grpLeft';
    Parent := FPanel;       
    Align := alClient;
    Caption := FLeftCaption;
  end;
  with Splitter1 do
  begin
    Name := 'Splitter1';
    Parent := Self;
    Align := alRight;
  end;
  with FPianoTracks[0] do
  begin
    Name := 'chklstCommon';
    Parent := Self;
    Align := alClient;
    DragMode := dmAutomatic;
    OnClickCheck := PianoTrackClick;
    OnDragDrop := PianoDragDrop;
    OnDragOver := PianoDragOver;
    Tag := Integer(thUnknow);
  end;
  with FPianoTracks[1] do
  begin
    Name := 'chklstRight';
    Parent := FRightGroupBox;
    Align := alClient;
    DragMode := dmAutomatic;
    OnClickCheck := PianoTrackClick;
    OnDragDrop := PianoDragDrop;
    OnDragOver := PianoDragOver;
    Tag := Integer(thRight);
  end;
  with FPianoTracks[2] do
  begin
    Name := 'chklstLeft';
    Parent := FLeftGroupBox;
    Align := alClient;
    DragMode := dmAutomatic;
    OnClickCheck := PianoTrackClick;
    OnDragDrop := PianoDragDrop;
    OnDragOver := PianoDragOver;
    Tag := Integer(thLeft);
  end;
end;

procedure TPianoTracks.SetLeftCaption(const Value: TCaption);
begin
  FLeftCaption := Value;
  FLeftGroupBox.Caption := FLeftCaption;
end;

procedure TPianoTracks.SetRightCaption(const Value: TCaption);
begin
  FRightCaption := Value;
  FRightGroupBox.Caption := FRightCaption;
end;

constructor TPianoTracks.Create(AOwner: TComponent);
begin
  inherited;
  //Align := alClient;
  FOwner := (AOwner as TWinControl);
  OnResize := PianoResize; // Resize;
  FTrackList := TStringList.Create;
  FLeftCaption := CLeftCaption;
  FRightCaption := CRightCaption;
  BuildTracks;
end;

destructor TPianoTracks.Destroy;
begin
  FreeAndNil(FTrackList);
  inherited;
end;

procedure TPianoTracks.PianoResize(Sender: TObject);
begin
  FPanel.Width := Width div 2;
  FRightGroupBox.Height := Height div 2;
end;

function TPianoTracks.GetTrackActive(Track: Byte): Boolean;
begin
  Result := True;
  if (Track > 0) and (Track < FTrackList.Count) then
    Result := TTrackInfo(FTrackList.Objects[Track]).TrackActive;
end;

procedure TPianoTracks.SetTrackActive(Track: Byte; Value: Boolean);
var
  i, j: integer;
begin
  if (Track > 0) and (Track < FTrackList.Count) then
    TTrackInfo(FTrackList.Objects[Track]).TrackActive := Value;
  for i := 0 to 2 do
    for j := 0 to FPianoTracks[i].Count - 1 do
    begin
      if Integer(FPianoTracks[i].Items.Objects[j]) = Track then
        FPianoTracks[i].Checked[j] := Value;
    end;
end;

procedure TPianoTracks.SetTrackHand(Track: Byte; Value: TTrackHand);
var
  PianoTrackSource, PianoTrackTarget: TCheckListBox;
  TrackInfo: TTrackInfo;
begin
  if (Track > 0) and (Track < FTrackList.Count) then
  begin
    TrackInfo := TTrackInfo(FTrackList.Objects[Track]);
    PianoTrackSource := FPianoTracks[Integer(TrackInfo.TrackHand)];
    PianoTrackTarget := FPianoTracks[Integer(Value)];
    PianoTrackTarget.Items.AddObject(
      TrackInfo.TrackName, TObject(TrackInfo.TrackIndex));
    PianoTrackTarget.Checked[PianoTrackTarget.Count - 1] := TrackInfo.TrackActive;
    PianoTrackSource.Items.Delete(PianoTrackSource.Items.IndexOfObject(TObject(TrackInfo.TrackIndex)));
    TrackInfo.TrackHand := Value;
  end;
end;

function TPianoTracks.GetTrackHand(Track: Byte): TTrackHand;
begin
  Result := thUnknow;
  if (Track > 0) and (Track < FTrackList.Count) then
    Result := TTrackInfo(FTrackList.Objects[Track]).TrackHand;
end;

procedure TPianoTracks.PianoDragDrop(Sender, Source: TObject; X,
  Y: Integer);
var
  PianoTrackSender, PianoTrackSource: TCheckListBox;
begin
  PianoTrackSender := TCheckListBox(Sender);
  PianoTrackSource := TCheckListBox(Source);
  if PianoTrackSource.ItemIndex = -1 then Exit;
  SetTrackHand(
    Integer(PianoTrackSource.Items.Objects[PianoTrackSource.ItemIndex]),
    TTrackHand(PianoTrackSender.Tag));
  if Assigned(FOnTrackMove) then
    FOnTrackMove(Sender);
end;

procedure TPianoTracks.PianoDragOver(Sender, Source: TObject; X,
  Y: Integer; State: TDragState; var Accept: Boolean);
var
  i: Byte;
begin
  Accept := Source is TCheckListBox;
  for i := 0 to 2 do
    Accept := Accept or (Source = FPianoTracks[i]);
end;

procedure TPianoTracks.PianoTrackClick(Sender: TObject);
var
  PianoTrack: TCheckListBox;
  bCheck: Boolean;
  iTrack: Integer;
begin
  PianoTrack := TCheckListBox(Sender);
  bCheck := PianoTrack.Checked[PianoTrack.ItemIndex];
  iTrack := Integer(PianoTrack.Items.Objects[PianoTrack.ItemIndex]);
  SetTrackActive(iTrack, bCheck);
  if Assigned(FOnTrackClick) then
    FOnTrackClick(Sender);
end;

procedure TPianoTracks.AddTrack(Info: TTrackInfo);
var
  PianoTrack: TCheckListBox;
begin
  FTrackList.AddObject(Info.TrackName, Info);
  PianoTrack := FPianoTracks[Integer(Info.TrackHand)];
  PianoTrack.Items.AddObject(Info.TrackName, TObject(Info.TrackIndex));
  PianoTrack.Checked[PianoTrack.Count - 1] := info.FTrackActive;
end;

procedure TPianoTracks.ClearTracks;
var
  i: integer;
begin
  FTrackList.Clear;
  for i := 0 to 2 do
    FPianoTracks[i].Clear;
end;

procedure Register;
begin
  RegisterComponents('Piano Suite', [TPianoTracks]);
end;

end.

