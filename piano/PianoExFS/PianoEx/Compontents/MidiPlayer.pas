{
  TMidiPlay, play midi tracks events.

  version 1.1
  Z.wan
  ziziiwan@hotmail.com
}

unit MidiPlayer;

interface

uses
  Windows, Messages, SysUtils, Classes, Controls, Forms, Dialogs, MMSystem,
  StdCtrls, ExtCtrls, WinProcs, MidiFile;

const
  TIMER_RESOLUTION = 10;
  WM_MULTIMEDIA_TIMER = WM_USER + 127;

type
  TTimerProc = procedure(uTimerID, uMsg: Integer; dwUser, dwParam1, dwParam2: DWORD); stdcall;

var
  MidiPlayerHandle: HWND;
  TimerProc: TTimerProc;
  MIDITimerID: Integer;
  TimerPeriod: Integer;

type
  TOnMidiEvent = procedure(Event: PMidiEvent) of object;
  TOnReadEvent = procedure(Track: Integer) of object;
  TOnSpeedChange = procedure(Value: Integer) of object;

  TMidiPlayer = class(TComponent)
  private
    FMidiFile: TMidiFile;

    FPriority: DWORD;
    FPlaying: Boolean;
    FStartTime: Integer;
    FCurrentPos: Double;
    FCurrentTime: Integer; // Current Playing Time
    FSpeed: Integer;
    procedure PlayEvent(iTrack: Integer; pEvent: PMidiEvent);

    procedure PlayAtTime(const iTime: Integer);
    procedure CalculateCurrentPos(const iTime: Integer);
    procedure SetCurrentPos(const Value: Double);
    procedure SetCurrentTime(const Value: Integer);
    procedure SetSpeed(const Value: Integer);
    procedure SetMidiFile(const Value: TMidiFile);
  protected
    FOnMidiEvent: TOnMidiEvent;
    FOnSpeedChange: TOnSpeedChange;
    FOnUpdateEvent: TNotifyEvent;
    FOnReadyEvent: TOnReadEvent;
    procedure MidiTimer(Sender: TObject);
    procedure WndProc(var Msg: TMessage);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure StartPlaying;
    procedure StopPlaying;
    procedure ContinuePlaying;
  published
    property MidiFile: TMidiFile read FMidiFile write SetMidiFile;
    property Speed: Integer read FSpeed write SetSpeed;
    property Playing: Boolean read FPlaying;
    property CurrentPos: Double read FCurrentPos write SetCurrentPos;
    property CurrentTime: Integer read FCurrentTime write SetCurrentTime;
    property OnMidiEvent: TOnMidiEvent read FOnMidiEvent write FOnMidiEvent;
    property OnSpeedChange: TOnSpeedChange read FOnSpeedChange write FOnSpeedChange;
    property OnUpdateEvent: TNotifyEvent read FOnUpdateEvent write FOnUpdateEvent;
    property OnReadyEvent: TOnReadEvent read FOnReadyEvent write FOnReadyEvent;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Piano Suite', [TMidiPlayer]);
end;

{ TMidiTimer}

procedure TimerCallBackProc(uTimerID, uMsg: Integer; dwUser, dwParam1, dwParam2: DWORD); stdcall;
begin
  PostMessage(HWND(dwUser), WM_MULTIMEDIA_TIMER, 0, 0);
end;

procedure SetMIDITimer;
var
  TimeCaps: TTimeCaps;
begin
  timeGetDevCaps(@TimeCaps, SizeOf(TimeCaps));
  if TIMER_RESOLUTION < TimeCaps.wPeriodMin then
    TimerPeriod := TimeCaps.wPeriodMin
  else if TIMER_RESOLUTION > TimeCaps.wPeriodMax then
    TimerPeriod := TimeCaps.wPeriodMax
  else
    TimerPeriod := TIMER_RESOLUTION;

  timeBeginPeriod(TimerPeriod);
  MIDITimerID := timeSetEvent(TimerPeriod, TimerPeriod, @TimerProc,
    DWORD(MidiPlayerHandle), TIME_PERIODIC);
  if MIDITimerID = 0 then
    timeEndPeriod(TimerPeriod);
end;

procedure KillMIDITimer;
begin
  timeKillEvent(MIDITimerID);
  timeEndPeriod(TimerPeriod);
end;

{ TMidiPlayer }

constructor TMidiPlayer.Create(AOwner: TComponent);
begin
  inherited Create(AOWner);

  FSpeed := 100;
  FStartTime := 0;
  FCurrentPos := 0.0;
  FCurrentTime := 0;

  MidiPlayerHandle := AllocateHWnd(WndProc);
  TimerProc := TimerCallBackProc;
  FPriority := GetPriorityClass(MidiPlayerHandle);
end;

destructor TMidiPlayer.Destroy;
begin
  SetPriorityClass(MidiPlayerHandle, FPriority);
  if MIDITimerID <> 0 then KillMIDITimer;
  DeallocateHWnd(MidiPlayerHandle);

  inherited;
end;

procedure TMidiPlayer.SetMidiFile(const Value: TMidiFile);
begin
  FMidiFile := Value;
end;

procedure TMidiPlayer.PlayEvent(iTrack: Integer; pEvent: PMidiEvent);
begin
  if PEvent.iEvent = $FF then
  begin
    if pEvent^.iData1 = $2F then // End this track
    begin
      FMidiFile.GetTrack(iTrack).Ready := True;
      if Assigned(FOnReadyEvent) then
        FOnReadyEvent(iTrack);
    end;
    if PEvent^.iData1 = $51 then
    begin
      FSpeed := Integer(Byte(PEvent^.sLetter[1])) shl 16 +
        Integer(Byte(PEvent^.sLetter[2])) shl 8 +
        Integer(Byte(PEvent^.sLetter[3]));
      FSpeed := 60000000 div FSpeed;
      if Assigned(FOnSpeedChange) then
        FOnSpeedChange(FSpeed);
    end;
  end;
end;

procedure TMIdiPlayer.CalculateCurrentPos(const iTime: Integer);
var
  secPerPulse: Double;
begin
  secPerPulse := 60000 / Speed / FMidiFile.GetMidiHead.PulsesPerQuarter;
  FCurrentPos := FCurrentPos + (iTime - FCurrentTime) / secPerPulse;
end;

procedure TMidiPlayer.SetCurrentPos(const Value: Double);
var
  iPositon: Integer;
  secPerPulse: Double;
begin
  if not Assigned(FMidiFile) then Exit;

  secPerPulse := 60000 / Speed / FMidiFile.GetMidiHead.PulsesPerQuarter;
  iPositon := Round((Value - FCurrentPos) * secPerPulse) + FCurrentTime;
  SetCurrentTime(iPositon);
end;

procedure TMidiPlayer.SetCurrentTime(const Value: Integer);
var
  i: Integer;
begin
  if not Assigned(FMidiFile) then Exit;

  if Value = 0 then // Replay
  begin
    FCurrentTime := 0;
    FCurrentPos := 0.0;
  end;

  CalculateCurrentPos(Value);
  FStartTime := GetTickCount - Value;
  for i := 0 to FMidiFile.TrackCount - 1 do
  begin
    with FMidiFile.GetTrack(i) do
    begin
      Position := 0;
      while (Position < EventCount) and (Round(FCurrentPos) > GetEvent(Position).iPositon) do
      begin
        PlayEvent(i, GetEvent(Position));
        Position := Position + 1;
      end;
    end;
  end;
  FCurrentTime := Value;
end;

procedure TMidiPlayer.PlayAtTime(const iTime: Integer);
var
  i: Integer;
begin
  if not Assigned(FMidiFile) then Exit;

  CalculateCurrentPos(iTime);
  for i := 0 to FMidiFile.TrackCount - 1 do
  begin
    with FMidiFile.GetTrack(i) do
    begin
      while (Position < EventCount) and (Round(FCurrentPos) > GetEvent(Position).iPositon) do
      begin
        PlayEvent(i, GetEvent(Position));
        if Active and Assigned(FOnMidiEvent) then
          FOnMidiEvent(GetEvent(Position));
        Position := Position + 1;
      end;
    end;
  end;
  FCurrentTime := iTime;
end;

procedure TMidiPlayer.StartPlaying;
begin
  SetCurrentTime(0);

  SetPriorityClass(MidiPlayerHandle, REALTIME_PRIORITY_CLASS);
  SetMIDITimer;
  FPlaying := True;
end;

procedure TMidiPlayer.ContinuePlaying;
begin
  SetCurrentTime(FCurrentTime);

  SetPriorityClass(MidiPlayerHandle, REALTIME_PRIORITY_CLASS);
  SetMIDITimer;
  FPlaying := True;
end;

procedure TMidiPlayer.StopPlaying;
begin
  KillMIDITimer;
  SetPriorityClass(MidiPlayerHandle, FPriority);
  FPlaying := False;
end;

procedure TMidiPlayer.MidiTimer(Sender: TObject);
begin
  if FPlaying then
  begin
    PlayAtTime(GetTickCount - FStartTime);
    if Assigned(FOnUpdateEvent) then FOnUpdateEvent(self);
  end;
end;

procedure TMidiPlayer.WndProc(var Msg: TMessage);
begin
  case Msg.Msg of
    WM_MULTIMEDIA_TIMER:
      begin
        try
          MidiTimer(self);
        except
          Application.HandleException(Self);
        end;
      end;
  else
    Msg.Result := DefWindowProc(MidiPlayerHandle, Msg.Msg, Msg.WParam, Msg.LParam);
  end;
end;

procedure TMidiPlayer.SetSpeed(const Value: Integer);
begin
  FSpeed := Value;
end;

end.

