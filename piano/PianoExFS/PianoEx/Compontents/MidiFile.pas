{
  Load a midifile and get access to tracks and events
  I did build this component to convert midifiles to wave files
  or play the files on a software synthesizer which I'm currenly
  building.

  version 1.3
  F.Bouwmans
  fbouwmans@spiditel.nl

  version 1.4
  Z.wan
  ziziiwan@hotmail.com
}

unit MidiFile;

interface

uses
  Windows, Messages, SysUtils, Classes, Controls, Forms, Dialogs, MMSystem,
  StdCtrls, ExtCtrls, Math;

type
  TChunkType = (ctIllegal, ctHeader, ctTrack);
  TFileType = (ftSingle, ftMultiSynch, ftMultiAsynch);
  TChannels = array[0..15] of Boolean;

  TMidiEvent = record
    iTrack: Byte;
    iEvent: Byte;
    iData1: Byte;
    iData2: Byte;
    sLetter: string;
    iPulses: Integer;
    iPositon: Integer;
    iSize: Integer;
  end;
  PMidiEvent = ^TMidiEvent;

  TMidiHead = record
    FileType: TFileType;
    NumberTracks: Integer;
    PulsesPerQuarter: Integer;
  end;
  PMidiHead = ^TMidiHead;

  TMidiTrack = class(TObject)
  private
    FActive: Boolean;
    FReady: Boolean;
    FEventList: TList;
    FTrackName: string;
    FTrackKeyword: string;
    FTrackCopyright: string;
    FChannels: TChannels;
    FInstrument: string;
    FPosition: Integer;
    FTime: Integer;
    FTrackSize: Integer;
    procedure CalaculateSize;
  protected
    function GetEventCount: Integer;
    function GetTrackLength: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddEvent(Event: PMidiEvent);
    function GetEvent(Index: Integer): PMidiEvent;
    function GetChannels(Index: Integer): Boolean;
  published
    property Active: Boolean read FActive write FActive;
    property Ready: Boolean read FReady write FReady;
    property Position: Integer read FPosition write FPosition;
    property Time: Integer read FTime write FTime;
    property TrackName: string read FTrackName;
    property EventCount: Integer read GetEventCount;
    property TrackLength: Integer read GetTrackLength;
  end;

  TMidiFile = class(TComponent)
  private
    FFileName: string;
    FMidiFile: file of Byte;
    FChunkType: TChunkType;
    FChunkLength: Integer;
    FChunkData: PByte;
    FChunkIndex: PByte;
    FChunkEnd: PByte;
    FMidiHead: TMidiHead;
    FMidiTrack: TMidiTrack;
    FTrackList: TList;
    procedure ReadChunkHeader;
    procedure ReadChunkContent;
    procedure ProcessHeaderChunk;
    procedure ProcessTrackChunk;
    procedure WriteChunkHeader;
    procedure WriteChunkContent;
    procedure RecordHeaderChunk;
    procedure RecordTrackChunk;
    procedure SetFileName(const Value: string);
    function GetMidiLength: Integer;
    function GetTrackCount: Integer;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure ReadFile;
    procedure WriteFile;
    procedure SetMidiHead(const Value: TMidiHead);
    function GetMidiHead: TMidiHead;
    procedure SetTrackList(const Value: TList);
    function GetTrackList: TList;
    procedure SetTrack(const Value: TMidiTrack);
    function GetTrack(Index: Integer): TMidiTrack;
  published
    property FileName: string read FFileName write SetFileName;
    //property MidiHead: TMidiHead read FMidiHead write SetMidiHead;
    //property MidiTrack: TMidiTrack read FMidiTrack write SetTrack;
    property MidiLength: Integer read GetMidiLength;
    property TrackCount: Integer read GetTrackCount;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Piano Suite', [TMidiFile]);
end;

{ Common }

procedure WriteVarLength(Value: LongInt; Mask: Byte; var PIndex: PByte);
var
  b: byte;
  i: Longint;
begin
  b := Value and $7F;
  i := Value shr 7;
  if i > 0 then
    WriteVarLength(i, $80, PIndex);
  b := b or mask;
  PIndex^ := b;
  Inc(PIndex);
end;

procedure WriteString(Value: string; var PIndex: PByte);
var
  i: Integer;
  Len: Integer;
begin
  Len := Length(Value);
  for i := 1 to Len do
  begin
    PIndex^ := Ord(Value[i]);
    inc(PIndex);
  end;
end;

function ReadVarLength(var PIndex: PByte): Integer;
var
  i: integer;
  b: byte;
begin
  b := $80;
  i := $0;
  while b > $7F do
  begin
    i := i shl 7;
    b := PIndex^;
    i := i + b and $7F;
    Inc(PIndex);
  end;
  Result := i;
end;

function ReadString(Len: Integer; var PIndex: PByte): string;
var
  c: PChar;
  i: Integer;
begin
  GetMem(C, Len + 1); ;
  c[Len] := Chr(0);
  for i := 0 to Len - 1 do
  begin
    c[i] := Chr(PIndex^);
    inc(PIndex);
  end;
  Result := string(c);
end;

procedure LengthToByte(Value: Integer; var b1, b2, b3, b4: Byte);
begin
  b1 := Value div $1000000;
  b2 := Value div $10000;
  b3 := Value div $100;
  b4 := Value;
end;

procedure ByteToLength(b1, b2, b3, b4: Byte; var Value: Integer);
begin
  Value := b4 + b3 * $100 + b2 * $10000 + b1 * $1000000;
end;

{ TMidiTrack }

constructor TMidiTrack.Create;
var
  i: Integer;
begin
  inherited Create;
  FEventList := TList.Create;
  FActive := True;
  FReady := False;
  FTrackName := '';
  FTrackKeyword := '';
  FTrackCopyright := '';
  for i := 0 to 15 do
    FChannels[i] := False;
  FInstrument := '';
  FPosition := 0;
  FTime := 0;
  FTrackSize := 0;
end;

destructor TMidiTrack.Destroy;
var
  i: integer;
begin
  for i := 0 to FEventList.Count - 1 do
    Dispose(PMidiEvent(FEventList[i]));
  FEventList.Free;
  inherited;
end;

procedure TMidiTrack.AddEvent(Event: PMidiEvent);
begin
  if (Event^.iEvent = $FF) then
  begin
    case Event^.iData1 of
      $1: FTrackKeyword := FTrackKeyword + Event^.sLetter;
      $2: FTrackCopyright := FTrackCopyright + Event^.sLetter;
      $3: FTrackName := FTrackName + Event^.sLetter;
      $4: FInstrument := FInstrument + Event^.sLetter;
    end;
  end else
  begin
    case Event^.iEvent of
      $B0..$BF, $C0..$CF: // control change, program change
        FChannels[Event^.iEvent and $F] := True;
    end;
  end;
  FPosition := FPosition + Event^.iPulses;
  Event^.iPositon := FPosition;
  FEventList.Add(Event);
end;

function TMidiTrack.GetEvent(Index: Integer): PMidiEvent;
begin
  if (Index >= 0) and (Index < FEventList.Count) then
    Result := PMidiEvent(FEventList[Index]) else
    Result := nil;
end;

function TMidiTrack.GetEventCount: Integer;
begin
  Result := FEventList.Count;
end;

function TMidiTrack.GetTrackLength: Integer;
begin
  Result := PMidiEvent(FEventList[FEventList.Count - 1]).iPositon;
end;

function TMidiTrack.GetChannels(Index: Integer): Boolean;
begin
  Result := FChannels[Index];
end;

procedure TMidiTrack.CalaculateSize;
var
  i: Integer;
begin
  FTrackSize := 0;
  for i := 0 to GetEventCount - 1 do
  begin
    Inc(FTrackSize, GetEvent(i)^.iSize);
  end;
end;

{ TMidiFile }

constructor TMidiFile.Create(AOwner: TComponent);
begin
  inherited Create(AOWner);

  FChunkType := ctIllegal;
  FChunkLength := -1;
  FChunkData := nil;
  FChunkIndex := nil;
  FChunkEnd := nil;

  FTrackList := TList.Create;
end;

destructor TMidiFile.Destroy;
var
  i: Integer;
begin
  if not (FChunkData = nil) then
    FreeMem(FChunkData);

  for i := 0 to GetTrackCount - 1 do
    TMidiTrack(FTrackList[i]).Free;
  FTrackList.Free;

  inherited;
end;

procedure TMidiFile.SetTrack(const Value: TMidiTrack);
begin
  FMidiTrack := Value;
end;

function TMidiFile.GetTrack(Index: Integer): TMidiTrack;
begin
  if (Index >= 0) and (Index < FTrackList.Count) then
    Result := TMidiTrack(FTrackList[Index]) else
    Result := nil;
end;

procedure TMidiFile.WriteChunkHeader;
var
  tmpByte: array[0..7] of Byte;
begin
  if FChunkType = ctHeader then
  begin
    tmpByte[0] := $4D; //M
    tmpByte[1] := $54; //T
    tmpByte[2] := $68; //h
    tmpByte[3] := $64; //d
  end;
  if FChunkType = ctTrack then
  begin
    tmpByte[0] := $4D; //M
    tmpByte[1] := $54; //T
    tmpByte[2] := $72; //r
    tmpByte[3] := $6B; //k
  end;
  LengthToByte(FChunkLength, tmpByte[4], tmpByte[5], tmpByte[6], tmpByte[7]);
  BlockWrite(FMidiFile, tmpByte, 8);
end;

procedure TMidiFile.ReadChunkHeader;
var
  tmpByte: array[0..7] of Byte;
begin
  FChunkType := ctIllegal;
  FChunkLength := -1;
  // read "4D 54 68 64", follow "00 00 00 06", Head
  // read "4D 54 72 6B", follow "00 00 0C DF", Track
  BlockRead(FMidiFile, tmpByte, 8);
  if (tmpByte[0] = $4D) and (tmpByte[1] = $54) then // MT
  begin
    if (tmpByte[2] = $68) and (tmpByte[3] = $64) then // hd, mean header
      FChunkType := ctHeader;
    if (tmpByte[2] = $72) and (tmpByte[3] = $6B) then // rk, mean track
      FChunkType := ctTrack;
  end;
  if FChunkType <> ctIllegal then
    ByteToLength(tmpByte[4], tmpByte[5], tmpByte[6], tmpByte[7], FChunkLength)
end;

procedure TMidiFile.WriteChunkContent;
begin
  if not (FChunkData = nil) then
    FreeMem(FChunkData);
  GetMem(FChunkData, FChunkLength + 1);
  FChunkIndex := FChunkData;
  FChunkEnd := PByte(Integer(FChunkIndex) + Integer(FChunkLength) - 1);
//  BlockWrite(FMidiFile, FChunkData^, FChunkLength);
end;

procedure TMidiFile.ReadChunkContent;
begin
  if not (FChunkData = nil) then
    FreeMem(FChunkData);
  GetMem(FChunkData, FChunkLength + 1);
  BlockRead(FMidiFile, FChunkData^, FChunkLength);
  FChunkIndex := FChunkData;
  FChunkEnd := PByte(Integer(FChunkIndex) + Integer(FChunkLength) - 1);
end;

procedure TMidiFile.RecordHeaderChunk;
begin
  FChunkType := ctHeader;
  FChunkLength := 6;
  WriteChunkHeader; // 4D 54 68 64 00 00 00 06
  WriteChunkContent;
  // ff ff, FileType
  FChunkIndex^ := 0;
  Inc(FChunkIndex);
  FChunkIndex^ := Integer(FMidiHead.FileType);
  // nn nn, NumberTracks
  Inc(FChunkIndex);
  FChunkIndex^ := FMidiHead.NumberTracks div $100;
  Inc(FChunkIndex);
  FChunkIndex^ := FMidiHead.NumberTracks;
  // dd dd, PulsesPerQuarter
  Inc(FChunkIndex);
  FChunkIndex^ := FMidiHead.PulsesPerQuarter div $100;
  Inc(FChunkIndex);
  FChunkIndex^ := FMidiHead.PulsesPerQuarter;

  BlockWrite(FMidiFile, FChunkData^, FChunkLength);
end;

procedure TMidiFile.ProcessHeaderChunk;
var
  i: Integer;
begin
  ReadChunkHeader;
  if FChunkType <> ctHeader then
    raise Exception.Create('Invalid midi format!');
  ReadChunkContent;

//  4D 54 68 64 00 00 00 06 ff ff nn nn dd dd
//
//前4个字节等同于ASCII码(MThd)，接着MThd之后的4个字节是头的大小。
//  它将一直是00 00 00 00 06，因为现行的头信息将一直是6字节。
//
//ff ff是文件的格式，有3种格式：
//0－单轨
//1－多规，同步
//2－多规，异步
//nn nn 是MIDI文件中的轨道数。
//dd dd 是每个4分音符节奏数。

  inc(FChunkIndex); // ff ff
  case FChunkIndex^ of
    0: FMidiHead.FileType := ftSingle;
    1: FMidiHead.FileType := ftMultiSynch;
    2: FMidiHead.FileType := ftMultiAsynch;
  end;
  inc(FChunkIndex); // nn nn
  i := FChunkIndex^ * $100;
  inc(FChunkIndex);
  FMidiHead.numberTracks := i + FChunkIndex^;
  inc(FChunkIndex); // dd dd
  i := FChunkIndex^ * $100;
  inc(FChunkIndex);
  FMidiHead.PulsesPerQuarter := i + FChunkIndex^;
end;

procedure TMidiFile.RecordTrackChunk;
var
  i: Integer;
  pEvent: PMidiEvent;
begin
  FMidiTrack.CalaculateSize; // Recalaculate TrackSize
  FChunkType := ctTrack;
  FChunkLength := FMidiTrack.FTrackSize;
  WriteChunkHeader;
  WriteChunkContent;

  for i := 0 to FMidiTrack.GetEventCount - 1 do
  begin
    pEvent := FMidiTrack.GetEvent(i);

    WriteVarLength(pEvent^.iPulses, 0, FChunkIndex);
    if pEvent^.iEvent >= $80 then
    begin
      FChunkIndex^ := pEvent^.iEvent;
      Inc(FChunkIndex);
    end;

    if pEvent^.iEvent = $FF then
    begin
      FChunkIndex^ := pEvent^.iData1;
      inc(FChunkIndex);
      WriteVarLength(Length(pEvent^.sLetter), 0, FChunkIndex);
      WriteString(pEvent^.sLetter, FChunkIndex);
    end else
    begin
      case pEvent^.iEvent of
        $80..$8F, $90..$9F, $A0..$AF, $B0..$BF, $E0..$EF:
          begin
            FChunkIndex^ := pEvent^.iData1;
            inc(FChunkIndex);
            FChunkIndex^ := pEvent^.iData2;
            inc(FChunkIndex);
          end;
        $C0..$CF, $D0..$DF:
          begin
            FChunkIndex^ := pEvent^.iData1;
            inc(FChunkIndex);
          end;
      end;
    end;
  end;
  BlockWrite(FMidiFile, FChunkData^, FChunkLength);
end;

procedure TMidiFile.ProcessTrackChunk;
var
  iEvent: Integer;
  iLength: Integer;
  pEvent: PMidiEvent;
  pStart: PByte;
begin
  ReadChunkHeader;
  if FChunkType <> ctTrack then
    raise Exception.Create('Invalid midi format!');
  ReadChunkContent;
  iEvent := 0;

//4D 54 72 6B xx xx xx xx
//
//与头一致，前4个字节是ASCII码(MTrk)，
//  紧跟MTrk的4个字节给出了以字节为单位的轨道的长度（不包括轨道头）。

  FMidiTrack := TMidiTrack.Create;
  FMidiTrack.FTrackSize := FChunkLength;
  FTrackList.Add(FMidiTrack); // Add to track list
  while Integer(FChunkIndex) < Integer(FChunkEnd) do
  begin
    New(pEvent); // New event
    pStart := FChunkIndex;
    pEvent^.iTrack := FTrackList.Count;
    // Each event starts with var length delta time
    iLength := ReadVarLength(FChunkIndex);
    if FChunkIndex^ >= $80 then
    begin
      iEvent := FChunkIndex^;
      inc(FChunkIndex);
    end;
    // Else it is a running status event (just the same event ads before)
    pEvent^.iEvent := iEvent;
    pEvent^.iPulses := iLength;
    if iEvent = $FF then
    begin
      pEvent^.iData1 := FChunkIndex^; // Type is stored in data1
      inc(FChunkIndex);
      iLength := ReadVarLength(FChunkIndex);
      pEvent^.sLetter := ReadString(iLength, FChunkIndex);
    end else
    begin
      // These are all midi events
      case iEvent of
        $80..$8F, // Note off
          $90..$9F, // Note on
          $A0..$AF, // Key aftertouch
          $B0..$BF, // Control change
          $E0..$EF: // Pitch wheel change
          begin
            pEvent^.iData1 := FChunkIndex^;
            inc(FChunkIndex);
            pEvent^.iData2 := FChunkIndex^;
            inc(FChunkIndex);
          end;
        $C0..$CF, // Program change
          $D0..$DF: // Channel aftertouch
          begin
            pEvent^.iData1 := FChunkIndex^;
            inc(FChunkIndex);
          end;
      end;
    end;
    pEvent.iSize := Integer(FChunkIndex) - Integer(pStart);
    FMidiTrack.AddEvent(pEvent);
  end; // End while
end;

procedure TMidiFile.WriteFile;
var
  i: Integer;
begin
  AssignFile(FMidiFile, FFileName);
  FileMode := 2;
  Rewrite(FMidiFile);

  RecordHeaderChunk;
  for i := 0 to GetTrackCount - 1 do
  begin
    FMidiTrack := GetTrack(i);
    RecordTrackChunk;
  end;

  CloseFile(FMidiFile);
end;

procedure TMidiFile.ReadFile;
var
  i: Integer;
begin
  for i := 0 to FTrackList.Count - 1 do
    TMidiTrack(FTrackList.Items[i]).Free;
  FTrackList.Clear;

  AssignFile(FMidiFile, FFileName);
  FileMode := 0;
  Reset(FMidiFile);

  ProcessHeaderChunk;
  while not eof(FMidiFile) do
    ProcessTrackChunk;

  CloseFile(FMidiFile);
end;

procedure TMidiFile.SetFileName(const Value: string);
begin
  FFileName := Value;
end;

procedure TMidiFile.SetMidiHead(const Value: TMidiHead);
begin
  FMidiHead := Value;
end;

procedure TMidiFile.SetTrackList(const Value: TList);
begin
  FTrackList := Value;
end;

function TMidiFile.GetMidiHead: TMidiHead;
begin
  Result := FMidiHead;
end;

function TMidiFile.GetTrackList: TList;
begin
  Result := FTrackList;
end;

function TMidiFile.GetMidiLength: Integer;
var
  i, iLen: Integer;
begin
  iLen := 0;
  for i := 0 to GetTrackCount - 1 do
  begin
    iLen := Max(iLen, TMidiTrack(FTrackList[i]).GetTrackLength);
  end;
  Result := iLen;
end;

function TMidiFile.GetTrackCount: Integer;
begin
  Result := FTrackList.Count;
end;

end.

