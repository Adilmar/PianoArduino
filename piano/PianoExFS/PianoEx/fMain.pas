//
//      -'`"_         -'`" \
//     /     \       /      "
//    /     /\\__   /  ___   \    ADDRESS:
//   |      | \  -"`.-(   \   |     XI'AN Science and Technology University
//   |      |  |     | \"  |  |   ZIP CODE:
//   |     /  /  "-"  \  \    |     7100**
//    \___/  /  (o o)  \  (__/    NAME:
//         __| _     _ |__          ZHONG WAN
//        (      ( )      )       EMAIL:
//         \_\.-.___.-./_/          ziziiwan@hotmail.com
//           __  | |  __          HOMEPAGE:
//          |  \.| |./  |           http://www.delphibox.com
//          | '#.   .#' |         OICQ:
//          |__/ '"" \__|           6036742
//        -/             \-       Write at Shanghai, China
//
//  Mid Piano Unit v1.0

unit fMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, MMSystem, ExtCtrls, ShellAPI, CheckLst, ComCtrls,
  ActnList, IniFiles, PianoKeyboard, PianoChannels, MidiIn, MidiCommon,
  MidiFile, MidiOut, PianoTracks, MidiPlayer;

type
  TfrmMain = class(TForm)
    trbOctave: TTrackBar;
    cbOutput: TComboBox;
    MidiOutput1: TMidiOutput;
    btnOpen: TBitBtn;
    OpenDialog1: TOpenDialog;
    edtSpeed: TEdit;
    btnPlay: TBitBtn;
    btnStop: TBitBtn;
    lstEvent: TListBox;
    edtTime: TEdit;
    cbKeysGroupCount: TComboBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    ActionList1: TActionList;
    actStop: TAction;
    actPlay: TAction;
    actOpen: TAction;
    MidiInput1: TMidiInput;
    PageControl1: TPageControl;
    tsTrack: TTabSheet;
    TabSheet1: TTabSheet;
    PageControl2: TPageControl;
    tsCommon: TTabSheet;
    tsChannel: TTabSheet;
    trbVolume: TTrackBar;
    Label6: TLabel;
    UpDown1: TUpDown;
    cbInput: TComboBox;
    Label7: TLabel;
    cbbColor: TComboBox;
    PianoTracks1: TPianoTracks;
    actReset: TAction;
    btnReset: TBitBtn;
    btnExit: TBitBtn;
    actExit: TAction;
    PianoChannels1: TPianoChannels;
    PianoKeyboard1: TPianoKeyboard;
    MidiPlayer1: TMidiPlayer;
    MidiFile1: TMidiFile;
    Label8: TLabel;
    actRecord: TAction;
    pbLength: TProgressBar;
    actInfo: TAction;
    BitBtn1: TBitBtn;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure cbKeysGroupCountChange(Sender: TObject);
    procedure actOpenExecute(Sender: TObject);
    procedure actPlayExecute(Sender: TObject);
    procedure actStopExecute(Sender: TObject);
    procedure trbOctaveChange(Sender: TObject);
    procedure cbOutputChange(Sender: TObject);
    procedure cbbColorChange(Sender: TObject);
    procedure trbVolumeChange(Sender: TObject);
    procedure UpDown1Changing(Sender: TObject; var AllowChange: Boolean);
    procedure MidiInput1MidiInput(Sender: TObject);
    procedure PianoKeyboard1Keyboard(Event, data1, data2: Byte);
    procedure FormShortCut(var Msg: TWMKey; var Handled: Boolean);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure PianoChannels1ChannelClick(Sender: TObject);
    procedure PianoTracks1TrackClick(Sender: TObject);
    procedure actResetExecute(Sender: TObject);
    procedure actExitExecute(Sender: TObject);
    procedure MidiPlayer1MidiEvent(Event: PMidiEvent);
    procedure MidiPlayer1ReadyEvent(Track: Integer);
    procedure MidiPlayer1SpeedChange(Value: Integer);
    procedure MidiPlayer1UpdateEvent(Sender: TObject);
    procedure actRecordExecute(Sender: TObject);
    procedure pbLengthMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure actInfoExecute(Sender: TObject);
  private
    //BtnCurrent: TPianoButton;
    procedure SaveIniFile;
    procedure LoadIniFile;
    procedure InitMidiIO;
    procedure MidiClose;
    procedure MidiOpen;
    procedure OpenMidiFile(FileName: string);
    procedure WMDropFiles(var Msg: TWMDropFiles); message WM_DROPFILES;
    function GetTrackColor(pEvent: PMidiEvent): TPianoColor;
    { Private declarations }
  protected
    procedure SentAllNotesOff;
  public
    { Public declarations }
  end;

const
  CMaxVolume = 65535;
  CStepVolume = 10000;

var
  MidiOpened: Boolean = False;

resourcestring
  rsErrorOpenMidi = 'Open MIDI Device failed, Please check configuration!';
  rsRebuildKeyboard = 'This operation will cost few time, continue?';
  rsBtnOpen = 'Open';
  rsBtnPlay = 'Play';
  rsBtnStop = 'Stop';
  rsBtnPause = 'Pause';
  rsBtnResume = 'Resume';

var
  frmMain: TfrmMain;

implementation

uses fInfo;

{$R *.dfm}

procedure TfrmMain.InitMidiIO;
var
  iDevice: Integer;
begin
  cbInput.Clear;
  for iDevice := 0 to MidiInput1.NumDevs - 1 do
  begin
    MidiInput1.DeviceID := iDevice;
    cbInput.Items.Add(MidiInput1.ProductName);
  end;
  cbInput.ItemIndex := 0;
  for iDevice := 0 to MidiOutput1.NumDevs - 1 do
  begin
    MidiOutput1.DeviceID := iDevice;
    cbOutput.Items.Add(MidiOutput1.ProductName);
  end;
  cbOutput.ItemIndex := 0;
end;

procedure TfrmMain.SaveIniFile;
begin
  with TInifile.Create(ChangeFileExt(ParamStr(0), '.ini')) do
  begin
    WriteString('PianoEx', 'LastFile', MidiFile1.Filename);
    WriteInteger('PianoEx', 'InputIndex', cbInput.ItemIndex);
    WriteInteger('PianoEx', 'OutPutIndex', cbOutput.ItemIndex);
    WriteInteger('PianoEx', 'OctaveIndex', trbOctave.Position);
    WriteInteger('PianoEx', 'CountIndex', cbKeysGroupCount.ItemIndex);
    WriteInteger('PianoEx', 'ColorIndex', cbbColor.ItemIndex);
    
    Free;
  end;
end;

procedure TfrmMain.LoadIniFile;
var
  MidiFileName: String;
begin
  with TInifile.Create(ChangeFileExt(ParamStr(0), '.ini')) do
  begin
    cbInput.ItemIndex := ReadInteger('PianoEx', 'InputIndex', 0);
    if cbInput.ItemIndex <> 0 then
      cbOutputChange(cbInput);
    cbOutput.ItemIndex := ReadInteger('PianoEx', 'OutPutIndex', 0);
    if cbOutput.ItemIndex <> 0 then
      cbOutputChange(cbOutput);

    trbOctave.Position := ReadInteger('PianoEx', 'OctaveIndex', 3);
    if trbOctave.Position <> 3 then
      PianoKeyboard1.PianoOctave := trbOctave.Position;
    cbKeysGroupCount.ItemIndex := ReadInteger('PianoEx', 'CountIndex', 0);
    if cbKeysGroupCount.ItemIndex <> 0 then
      PianoKeyboard1.PianoGroup := StrToInt(cbKeysGroupCount.Text);
    cbbColor.ItemIndex := ReadInteger('PianoEx', 'ColorIndex', 0);
    if cbbColor.ItemIndex <> 0 then
      PianoKeyboard1.PianoColor := TPianoColor(cbbColor.ItemIndex);

    MidiFileName := ReadString('PianoEx', 'LastFile', '');
    if (MidiFileName <> '') and (FileExists(MidiFileName)) then
      OpenMidiFile(MidiFileName);

    Free;
  end;
end;

procedure TfrmMain.MidiOpen;
begin
  if cbInput.Text <> '' then
  begin
    MidiInput1.ProductName := cbInput.Text;
    MidiInput1.Open;
    MidiInput1.Start;
  end;
  if cbOutput.Text <> '' then
  begin
    MidiOutput1.ProductName := cbOutput.Text;
    MidiOpened := MidiOutput1.Open;
    if not MidiOpened then
      ShowMessage(rsErrorOpenMidi);
  end;
end;

procedure TfrmMain.MidiClose;
begin
  if MidiOpened then
  begin
    MidiOutput1.Close;
    MidiOpened := False;
  end;
  MidiInput1.Close;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  DragAcceptFiles(Handle, True); // Enable dragfile
  // Find Midi Input/Output
  InitMidiIO;
  // Open Midi Device
  MidiOpen;
  // Set Midi Volume
  trbVolume.Max := CMaxVolume div CStepVolume;
  trbVolume.Position := trbVolume.Max - MidiOutput1.MidiVolume div CStepVolume;
  // IniFile
  LoadIniFile;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  MidiClose;
  // IniFile
  SaveIniFile;
end;

procedure TfrmMain.SentAllNotesOff;
var
  mEvent: TMyMidiEvent;
  iChannel: Integer;
begin
  mEvent := TMyMidiEvent.Create;
  for iChannel := 0 to 15 do
  begin
    mEvent.MidiMessage := $B0 + iChannel;
    mEvent.data1 := $7E;
    mEvent.data2 := 0;
    if MidiOpened then
      MidiOutput1.PutMidiEvent(mEvent);
    PianoKeyboard1.DoMidiEvent(mEvent.MidiMessage, mEvent.data1, mEvent.data2, TPianoColor(cbbColor.ItemIndex));
  end;
  mEvent.Destroy;
  // Reset controls
end;

function TfrmMain.GetTrackColor(pEvent: PMidiEvent): TPianoColor;
var
  iTrack: Byte;
begin
  Result := TPianoColor(-1);
  if pEvent^.iEvent = $FF then Exit;
  iTrack := pEvent.iTrack - 1;
  case PianoTracks1.GetTrackHand(iTrack) of
    thUnknow: Result := TPianoColor(cbbColor.ItemIndex);
    thLeft: Result := pcBlue;
    thRight: Result := pcRed;
  end;
end;

procedure TfrmMain.MidiPlayer1MidiEvent(Event: PMidiEvent);
var
  mEvent: TMyMidiEvent;
begin
  if not (Event^.iEvent = $FF) then
  begin
    mEvent := TMyMidiEvent.Create;
    mEvent.MidiMessage := Event^.iEvent;
    mEvent.data1 := Event^.iData1;
    mEvent.data2 := Event^.iData2;
    MidiOutput1.PutMidiEvent(mEvent);
    PianoChannels1.DoChannelBar(mEvent.MidiMessage and $F, mEvent.Data1);
    mEvent.Destroy;
  end else
  begin
    if (Event^.iData1 >= 1) and (Event^.iData1 < 15) then
    begin
      lstEvent.Items.Add(IntToStr(Event^.iData1) + ' ' + Event^.sLetter);
      PostMessage(lstEvent.Handle, WM_VSCROLL, SB_LINEDOWN, 0);
    end
  end;
  PianoKeyboard1.DoMidiEvent(Event^.iEvent, Event^.iData1, Event^.iData2, GetTrackColor(Event));
end;

procedure TfrmMain.MidiPlayer1ReadyEvent(Track: Integer);
var
  i: Integer;
  b: Boolean;
begin
  b := True;
  for i := 0 to MidiFile1.TrackCount - 1 do
    if not MidiFile1.GetTrack(i).Ready then
      b := False;
  if b then
    actStop.Execute;
end;

procedure TfrmMain.MidiPlayer1SpeedChange(Value: Integer);
begin
  UpDown1.Position := Value;
  MidiPlayer1.Speed := Value;
end;

procedure TfrmMain.MidiPlayer1UpdateEvent(Sender: TObject);
begin
  edtTime.Text := MyTimeToStr(MidiPlayer1.CurrentTime);
  edtTime.Update;
  pbLength.Position := Round(MidiPlayer1.CurrentPos);
  pbLength.Update;
end;

procedure TfrmMain.cbKeysGroupCountChange(Sender: TObject);
begin
  if MessageDlg(rsRebuildKeyboard, mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    PianoKeyboard1.PianoGroup := StrToInt(cbKeysGroupCount.Text);
  end else
  begin
    cbKeysGroupCount.ItemIndex := cbKeysGroupCount.Items.IndexOf(IntToStr(PianoKeyboard1.PianoGroup));
  end;
end;

procedure TfrmMain.OpenMidiFile(FileName: string);
var
  s: string;
  i, j: Integer;
  Track: TMidiTrack;
  TrackInfo: TTrackInfo;
begin
  actStop.Execute; // Stop first

  MidiFile1.Filename := FileName;
  MidiFile1.ReadFile;
  edtSpeed.Text := IntToStr(MidiPlayer1.Speed);
  pbLength.Max := MidiFile1.MidiLength;
  // Reset Channels
  PianoChannels1.ResetChannel(False);
  // Reset Tracks
  PianoTracks1.ClearTracks;
  for i := 0 to MidiFile1.TrackCount - 1 do
  begin
    Track := MidiFile1.GetTrack(i);
    s := '';
    if i < 10 then s := '0' + IntToStr(i) else s := IntToStr(i);
    s := Format('[%s] %s', [s, Track.TrackName]);
    TrackInfo := TTrackInfo.Create;
    TrackInfo.TrackName := s;
    TrackInfo.TrackIndex := i;
    TrackInfo.TrackActive := True;
    TrackInfo.TrackHand := thUnknow;
    PianoTracks1.AddTrack(TrackInfo);
    // set channel enable
    for j := 0 to 15 do
    begin
      if Track.GetChannels(j) then
        PianoChannels1.DoChannelBox(j, True);
    end;
  end;
  if MidiFile1.TrackCount = 3 then
  begin
    PianoTracks1.SetTrackHand(1, thRight);
    PianoTracks1.SetTrackHand(2, thLeft);
  end;
//  MidiFile1.FileName := 'D:\My Documents\My Music\ove\1.mid';
//  MidiFile1.WriteFile;
end;

procedure TfrmMain.actOpenExecute(Sender: TObject);
begin
  if MidiPlayer1.Playing then
    actPlay.Execute; // Pause first

  if OpenDialog1.Execute then
    OpenMidiFile(OpenDialog1.FileName);
end;

procedure TfrmMain.actPlayExecute(Sender: TObject);
begin
  if MidiFile1.Filename = '' then exit;
  if not MidiOpened then Exit;
  case actPlay.Tag of
    0: // Play
      begin
        MidiPlayer1.StartPlaying;
        actPlay.Tag := 1;
        actPlay.Caption := rsBtnPause;
      end;
    1: // Pause
      begin
        MidiPlayer1.StopPlaying;
        SentAllNotesOff;
        actPlay.Tag := 2;
        actPlay.Caption := rsBtnResume;
      end;
    2: // Continue
      begin
//        try
//          MidiFile1.PlayToTime(MyStrToTime(edtTime.Text));
//        except
//        end;
        MidiPlayer1.ContinuePlaying;
        actPlay.Tag := 1;
        actPlay.Caption := rsBtnPause;
      end;
  end;
end;

procedure TfrmMain.actStopExecute(Sender: TObject);
begin
  MidiPlayer1.StopPlaying;
  SentAllNotesOff;

  actPlay.Tag := 0; // Set PlayButton to Play status
  actPlay.Caption := rsBtnPlay;
  edtTime.Text := '0:00:00.000';
  pbLength.Position := 0;
end;

procedure TfrmMain.trbOctaveChange(Sender: TObject);
begin
  PianoKeyboard1.PianoOctave := trbOctave.Position;
end;

procedure TfrmMain.cbOutputChange(Sender: TObject);
begin
  if MidiOpened then
    SentAllNotesOff;
  MidiClose;
  MidiOpen;
end;

procedure TfrmMain.WMDropFiles(var Msg: TWMDropFiles);
var
  CFileName: array[0..MAX_PATH] of Char;
  CExt: string;
begin
  try
    if DragQueryFile(Msg.Drop, 0, CFileName, MAX_PATH) > 0 then
    begin
      CExt := ExtractFileExt(CFileName);
      if (CExt = '.mid') or (CExt = '.midi') then
        OpenMidiFile(CFileName);
    end;
  finally
    DragFinish(Msg.Drop);
  end;
end;

procedure TfrmMain.cbbColorChange(Sender: TObject);
begin
  PianoKeyboard1.PianoColor := TPianoColor(cbbColor.ItemIndex);
end;

procedure TfrmMain.trbVolumeChange(Sender: TObject);
begin
  MidiOutput1.MidiVolume := CMaxVolume - trbVolume.Position * CStepVolume;
end;

procedure TfrmMain.UpDown1Changing(Sender: TObject;
  var AllowChange: Boolean);
begin
  MidiPlayer1.Speed := UpDown1.Position;
end;

procedure TfrmMain.MidiInput1MidiInput(Sender: TObject);
var
  thisEvent: TMyMidiEvent;
begin
  with (Sender as TMidiInput) do
  begin
    while (MessageCount > 0) do
    begin
      // Get the event as an object
      thisEvent := GetMidiEvent;

      // Echo to the output device
      MidiOutput1.PutMidiEvent(thisEvent);
      // Put event to GUI
      PianoKeyboard1.DoMidiEvent(thisEvent.MidiMessage, thisEvent.Data1, thisEvent.Data2, TPianoColor(-1));

      //  Event was dynamically created by GetMidiEvent so must free it here
      thisEvent.Free;
    end;
  end;
end;

procedure TfrmMain.PianoKeyboard1Keyboard(Event, data1, data2: Byte);
begin
  MidiOutput1.PutShort(Event, data1, data2);
end;

procedure TfrmMain.FormShortCut(var Msg: TWMKey; var Handled: Boolean);
begin
  PianoKeyboard1.DoPianoShortCut(Msg, Handled);
end;

procedure TfrmMain.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  PianoKeyboard1.DoPianoKeyDown(Sender, Key, Shift);
end;

procedure TfrmMain.FormKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  PianoKeyboard1.DoPianoKeyUp(Sender, key, Shift);
end;

procedure TfrmMain.PianoChannels1ChannelClick(Sender: TObject);
var
  i: Integer;
  bCheck: Boolean;
  chkSender: TCheckBox;
begin
  SentAllNotesOff;
  chkSender := (Sender as TCheckBox);
  bCheck := chkSender.Checked;
  for i := 0 to MidiFile1.TrackCount - 1 do
    if MidiFile1.GetTrack(i).GetChannels(chkSender.Tag) then
    begin
      PianoTracks1.SetTrackActive(i, bCheck);
      MidiFile1.GetTrack(i).Active := bCheck;
    end;
end;

procedure TfrmMain.PianoTracks1TrackClick(Sender: TObject);
var
  i: Integer;
  bCheck: Boolean;
  chklstSender: TCheckListBox;
  iTrack: Integer;
begin
  SentAllNotesOff;
  chklstSender := TCheckListBox(Sender);
  iTrack := Integer(chklstSender.Items.Objects[chklstSender.ItemIndex]);
  bCheck := chklstSender.Checked[chklstSender.ItemIndex];
  for i := 0 to 15 do
    if MidiFile1.GetTrack(iTrack).GetChannels(i) then
      PianoChannels1.DoChannelBox(i, bCheck);
  // Set Midi event
  MidiFile1.GetTrack(iTrack).Active := bCheck;
end;

procedure TfrmMain.actResetExecute(Sender: TObject);
begin
  actStop.Execute;
  PianoChannels1.ResetChannel(True);
  PianoKeyboard1.PianoColor := TPianoColor(cbbColor.ItemIndex);
end;

procedure TfrmMain.actExitExecute(Sender: TObject);
begin
  actStop.Execute;
  Close;
end;

procedure TfrmMain.actRecordExecute(Sender: TObject);
begin
//
end;

procedure TfrmMain.pbLengthMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if MidiPlayer1.Playing then
  begin
    SentAllNotesOff;
    MidiPlayer1.CurrentPos := pbLength.Max * (x / pbLength.Width);
  end;
end;

procedure TfrmMain.actInfoExecute(Sender: TObject);
begin
  if not Assigned(frmInfo) then
    Application.CreateForm(TfrmInfo, frmInfo);
  frmInfo.ShowModal;
end;

end.

