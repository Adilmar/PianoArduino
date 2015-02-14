unit fInfo;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, MidiFile, StdCtrls, ExtCtrls, ComCtrls, MidiCommon;

type
  TfrmInfo = class(TForm)
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    rgFileType: TRadioGroup;
    LabeledEdit1: TLabeledEdit;
    LabeledEdit2: TLabeledEdit;
    PageControl1: TPageControl;
    Timer1: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    MidiHeader: TMidiHead;
    TrackList: TList;
    procedure AddMidiFileTracks;
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmInfo: TfrmInfo;

implementation

uses fMain;

{$R *.dfm}

procedure TfrmInfo.FormCreate(Sender: TObject);
begin
  MidiHeader := frmMain.MidiFile1.GetMidiHead;
  TrackList := frmMain.MidiFile1.GetTrackList;
end;

procedure TfrmInfo.AddMidiFileTracks;
var
  i, j: Integer;

  tsTrack: TTabSheet;
  lvTrack: TListView;
  Item: TListItem;

  Track: TMidiTrack;
  Event: PMidiEvent;
begin
  for i := PageControl1.PageCount - 1 downto 0 do
    PageControl1.Pages[i].Free;

  for i := 0 to TrackList.Count - 1 do
  begin
    tsTrack := TTabSheet.Create(Self);
    with tsTrack do
    begin
      Name := 'tsTrack' + IntToStr(i);
      Parent := PageControl1;
      PageControl := PageControl1;
      Caption := 'Track ' + IntToStr(i + 1);
    end;

    lvTrack := TListView.Create(Self);
    with lvTrack do
    begin
      Name := 'lvTrack' + IntToStr(i);
      Parent := tsTrack;
      Align := alClient;
      with Columns.Add do begin
        Caption := 'event';
      end;
      with Columns.Add do begin
        Caption := 'data1';
        Width := 60;
      end;
      with Columns.Add do begin
        Caption := 'data2';
        Width := 60;
      end;
      with Columns.Add do begin
        Caption := 'postion';
        Width := 110;
      end;
      with Columns.Add do begin
        Caption := 'string';
        Width := 200;
        //AutoSize := True;
      end;
      RowSelect := True;
      TabOrder := 0;
      ViewStyle := vsReport;
    end;

    Track := TMidiTrack(TrackList[i]);
    for j := 0 to Track.EventCount - 1 do
    begin
      Event := Track.GetEvent(j);
      Item := lvTrack.Items.Add;
      Item.Caption := '$' + IntToHex(Event^.iEvent, 2);
      Item.SubItems.Add('$' + IntToHex(Event^.iData1, 2));
      Item.SubItems.Add('$' + IntToHex(Event^.iData2, 2));
      Item.SubItems.Add(IntToStr(Event^.iPositon));
      Item.SubItems.Add(Event^.sLetter);
    end;
    Application.ProcessMessages;
  end;
end;

procedure TfrmInfo.FormShow(Sender: TObject);
begin
  rgFileType.ItemIndex := Integer(MidiHeader.FileType);
  LabeledEdit1.Text := IntToStr(MidiHeader.NumberTracks);
  LabeledEdit2.Text := IntToStr(MidiHeader.PulsesPerQuarter);
  Timer1.Enabled := True;
end;

procedure TfrmInfo.Timer1Timer(Sender: TObject);
begin
  Timer1.Enabled := False;
  AddMidiFileTracks;
end;

end.

