unit MidiOut;

interface

uses
  SysUtils, WinTypes, WinProcs, Messages, Classes, Controls, Forms,
  MMSystem, MidiCommon;

type
  MidiOutputState = (mosOpen, mosClosed);
  EMidiOutputError = class(Exception);

  { These are the equivalent of constants prefixed with mod_
    as defined in MMSystem. See SetTechnology }
  OutPortTech = (
    opt_None, { none }
    opt_MidiPort, { output port }
    opt_Synth, { generic internal synth }
    opt_SQSynth, { square wave internal synth }
    opt_FMSynth, { FM internal synth }
    opt_Mapper); { MIDI mapper }
  TechNameMap = array[OutPortTech] of string[18];

  { These are Volume Record type}
  TVolumeRec = record
    case Cardinal of
      0: (LongVolume: Longint);
      1: (LeftVolume,
        RightVolume: Word);
  end;

const
  TechName: TechNameMap = ('None', 'MIDI Port', 'Generic Synth',
    'Square Wave Synth', 'FM Synth', 'MIDI Mapper');

type
  TMidiOutput = class(TComponent)
  protected
    Handle: THandle; { Window handle used for callback notification }
    FDeviceID: Integer; { MIDI device ID }
    FMIDIHandle: Hmidiout; { Handle to output device }
    FState: MidiOutputState; { Current device state }
    PCtlInfo: PMidiCtlInfo; { Pointer to control info for DLL }
    PBuffer: PCircularBuffer; { Output queue for PutTimedEvent, set by Open }
    FError: Word; { Last MMSYSTEM error }
    { Stuff from midioutCAPS }
    FDriverVersion: Version; { Driver version from midioutGetDevCaps }
    FProductName: string; { product name }
    FTechnology: OutPortTech; { Type of MIDI output device }
    FVoices: Word; { Number of voices (internal synth) }
    FNotes: Word; { Number of notes (internal synth) }
    FChannelMask: Word; { Bit set for each MIDI channels that the device responds to (internal synth) }
    FSupport: DWORD; { Technology supported (volume control, patch caching etc. }
    FNumdevs: Word; { Number of MIDI output devices on system }
    FVolume: TVolumeRec; { Volume of MIDI }
    FOnMidiOutput: TNotifyEvent; { Sysex output finished }
    procedure MidiOutput(var Message: TMessage);
    procedure SetDeviceID(DeviceID: Integer);
    procedure SetProductName(NewProductName: string);
    procedure SetTechnology(NewTechnology: OutPortTech);
    procedure SetVolume(Volume: Word);
    function GetVolume: Word;
  public
    { Properties }
    property MIDIHandle: Hmidiout read FMIDIHandle;
    property DriverVersion: Version { Driver version from midioutGetDevCaps }
      read FDriverVersion;
    property Technology: OutPortTech { Type of MIDI output device }
      read FTechnology write SetTechnology default opt_Synth;
    property Voices: Word read FVoices; { Number of voices (internal synth) }
    property Notes: Word read FNotes; { Number of notes (internal synth) }
    property ChannelMask: Word read FChannelMask;
    { Bit set for each MIDI channels that the device responds to (internal synth) }
    property Support: DWORD read FSupport;
    { Technology supported (volume control, patch caching etc. }
    property Error: Word read FError;
    property Numdevs: Word read FNumdevs;
    { Methods }
    function Open: Boolean; virtual;
    function Close: Boolean; virtual;
    procedure PutMidiEvent(theEvent: TMyMidiEvent); virtual;
    procedure PutShort(MidiMessage: Byte; Data1: Byte; Data2: Byte); virtual;
    procedure PutLong(TheSysex: Pointer; msgLength: Word); virtual;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    { Some functions to decode and classify incoming messages would be nice }
  published
    { TODO: Property editor with dropdown list of product names }
    property ProductName: string read FProductName write SetProductName;
    property DeviceID: Integer read FDeviceID write SetDeviceID default 0;
    property MidiVolume: Word read GetVolume write SetVolume stored False;
    { Events }
    property OnMidiOutput: TNotifyEvent read FOnMidiOutput write FOnMidiOutput;
  end;

procedure Register;

implementation

constructor TMidiOutput.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FState := mosClosed;
  FNumdevs := midiOutGetNumDevs;
  { Create the window for callback notification }
  if not (csDesigning in ComponentState) then
  begin
    Handle := AllocateHwnd(MidiOutput);
  end;
end;

destructor TMidiOutput.Destroy;
begin
  if FState = mosOpen then
    Close;
  if (PCtlInfo <> nil) then
    GlobalSharedLockedFree(PCtlinfo^.hMem, PCtlInfo);
  DeallocateHwnd(Handle);
  inherited Destroy;
end;

procedure TMidiOutput.SetDeviceID(DeviceID: Integer);
{ Set the output device ID and change the other properties to match }
var
  midioutCaps: TmidioutCaps;
begin
  if FState = mosOpen then
    raise EMidiOutputError.Create('Change to DeviceID while device was open')
  else
  begin
    if (DeviceID >= midioutGetNumDevs) and (DeviceID <> MIDI_MAPPER) then
      raise EMidiOutputError.Create('Invalid device ID') else
    begin
      FDeviceID := DeviceID;
      { Set the name and other midioutCAPS properties to match the ID }
      FError := midioutGetDevCaps(DeviceID, @midioutCaps, sizeof(TmidioutCaps));
      if Ferror > 0 then
        raise EMidiOutputError.Create(MidiIOErrorString(False, FError));
      with midiOutCaps do
      begin
        FProductName := StrPas(szPname);
        FDriverVersion := vDriverVersion;
        FTechnology := OutPortTech(wTechnology);
        FVoices := wVoices;
        FNotes := wNotes;
        FChannelMask := wChannelMask;
        FSupport := dwSupport;
      end;
    end;
  end;
end;

procedure TMidiOutput.SetProductName(NewProductName: string);
{ Set product name property and put the matching output device number in FDeviceID }
var
  midioutCaps: TmidioutCaps;
  testDeviceID: Integer;
  testProductName: string;
begin
  if FState = mosOpen then
    raise EMidiOutputError.Create('Change to ProductName while device was open')
  else
  begin
    if not (csLoading in ComponentState) then
    begin
      { Loop uses -1 to test for MIDI_MAPPER as well }
      for testDeviceID := -1 to (midioutGetNumDevs - 1) do
      begin
        FError := midioutGetDevCaps(testDeviceID, @midioutCaps, sizeof(TmidioutCaps));
        if Ferror > 0 then
          raise EMidiOutputError.Create(MidiIOErrorString(False, FError));
        testProductName := StrPas(midioutCaps.szPname);
        if testProductName = NewProductName then
        begin
          FProductName := NewProductName;
          Break;
        end;
      end;
      if FProductName <> NewProductName then
        raise EMidiOutputError.Create('MIDI output Device ' + NewProductName + ' not installed') else
        SetDeviceID(testDeviceID);
    end;
  end;
end;

procedure TMidiOutput.SetTechnology(NewTechnology: OutPortTech);
{ Set output technology property and put the matching output device number in FDeviceID }
var
  midiOutCaps: TMidiOutCaps;
  testDeviceID: Integer;
  testTechnology: OutPortTech;
begin
  if FState = mosOpen then
    raise EMidiOutputError.Create('Change to Product Technology while device was open') else
  begin
    { Loop uses -1 to test for MIDI_MAPPER as well }
    for testDeviceID := -1 to (midiOutGetNumDevs - 1) do
    begin
      FError := midiOutGetDevCaps(testDeviceID, @midiOutCaps, sizeof(TMidiOutCaps));
      if Ferror > 0 then
        raise EMidiOutputError.Create(MidiIOErrorString(False, FError));
      testTechnology := OutPortTech(midiOutCaps.wTechnology);
      if testTechnology = NewTechnology then
      begin
        FTechnology := NewTechnology;
        Break;
      end;
    end;
    if FTechnology <> NewTechnology then
      raise EMidiOutputError.Create('MIDI output technology ' + TechName[NewTechnology] + ' not installed') else
      SetDeviceID(testDeviceID);
  end;
end;

function TMidiOutput.Open: Boolean;
var
  hMem: THandle;
begin
  Result := False;
  try
    { Create the control info for the DLL }
    if (PCtlInfo = nil) then
    begin
      PCtlInfo := GlobalSharedLockedAlloc(Sizeof(TMidiCtlInfo), hMem);
      PctlInfo^.hMem := hMem;
    end;
    Pctlinfo^.hWindow := Handle; { Control's window handle }
    FError := midioutOpen(
      @FMidiHandle,
      FDeviceId,
      DWORD(@midiHandler),
      DWORD(PCtlInfo),
      CALLBACK_FUNCTION);
    if (FError <> 0) then
      { TODO: use CreateFmtHelp to add MIDI device name/ID to message }
      raise EMidiOutputError.Create(MidiIOErrorString(False, FError)) else
    begin
      Result := True;
      FState := mosOpen;
    end;
  except
    if PCtlInfo <> nil then
    begin
      GlobalSharedLockedFree(PCtlInfo^.hMem, PCtlInfo);
      PCtlInfo := nil;
    end;
  end;
end;

procedure TMidiOutput.PutShort(MidiMessage: Byte; Data1: Byte; Data2: Byte);
var
  thisMsg: DWORD;
begin
  thisMsg := DWORD(MidiMessage) or
    (DWORD(Data1) shl 8) or
    (DWORD(Data2) shl 16);
  FError := midiOutShortMsg(FMidiHandle, thisMsg);
  if Ferror > 0 then
    raise EMidiOutputError.Create(MidiIOErrorString(False, FError));
end;

procedure TMidiOutput.PutLong(TheSysex: Pointer; msgLength: Word);
{ Notes: This works asynchronously }
var
  MyMidiHdr: TMyMidiHdr;
begin
  { Initialize the header and allocate buffer memory }
  MyMidiHdr := TMyMidiHdr.Create(msgLength);
  StrMove(MyMidiHdr.SysexPointer, TheSysex, msgLength);
  { Store the MyMidiHdr address in the header so we can find it again quickly }
  MyMidiHdr.hdrPointer^.dwUser := DWORD(MyMidiHdr);
  { Get MMSYSTEM's blessing for this header }
  FError := midiOutPrepareHeader(FMidiHandle, MyMidiHdr.hdrPointer, sizeof(TMIDIHDR));
  if Ferror > 0 then
    raise EMidiOutputError.Create(MidiIOErrorString(False, FError));
  { Send it }
  FError := midiOutLongMsg(FMidiHandle, MyMidiHdr.hdrPointer, sizeof(TMIDIHDR));
  if FError > 0 then
    raise EMidiOutputError.Create(MidiIOErrorString(False, FError));
end;

procedure TMidiOutput.PutMidiEvent(theEvent: TMyMidiEvent);
begin
  if FState <> mosOpen then
    raise EMidiOutputError.Create('MIDI Output device not open');
  with theEvent do
  begin
    if Sysex = nil then
    begin
      PutShort(MidiMessage, Data1, Data2)
    end else
      PutLong(Sysex, SysexLength);
  end;
end;

function TMidiOutput.Close: Boolean;
begin
  Result := False;
  if FState = mosOpen then
  begin
    { Note this sends a lot of fast control change messages which some synths can't handle.
      TODO: Make this optional. }
    FError := midioutClose(FMidiHandle);
    if Ferror <> 0 then
      raise EMidiOutputError.Create(MidiIOErrorString(False, FError))
    else
      Result := True;
  end;
  FMidiHandle := 0;
  FState := mosClosed;
end;

function TMidiOutput.GetVolume: Word;
begin
  FVolume.LongVolume := 0;
  FError := midiOutGetVolume(DeviceID, @FVolume.LongVolume);
  if Ferror <> 0 then
    raise EMidiOutputError.Create(MidiIOErrorString(False, FError));
  Result := FVolume.LeftVolume;
end;

procedure TMidiOutput.SetVolume(Volume: Word);
begin
  FVolume.LeftVolume := Volume;
  FVolume.RightVolume := FVolume.LeftVolume;
  FError := midiOutSetVolume(DeviceID, FVolume.LongVolume);
  if Ferror <> 0 then
    raise EMidiOutputError.Create(MidiIOErrorString(False, FError));
end;

procedure TMidiOutput.MidiOutput(var Message: TMessage);
{ Triggered when sysex output from PutLong is complete }
var
  MyMidiHdr: TMyMidiHdr;
  thisHdr: PMidiHdr;
begin
  if Message.Msg = Mom_Done then
  begin
    { Find the MIDIHDR we used for the output. Message.lParam is its address }
    thisHdr := PMidiHdr(Message.lParam);
    { Remove it from the output device }
    midiOutUnprepareHeader(FMidiHandle, thisHdr, sizeof(TMIDIHDR));
    { Get the address of the MyMidiHdr object containing this MIDIHDR structure.
      We stored this address in the PutLong procedure }
    MyMidiHdr := TMyMidiHdr(thisHdr^.dwUser);
    { Header and copy of sysex data no longer required since output is complete }
    MyMidiHdr.Free;
    { Call the user's event handler if any }
    if Assigned(FOnMidiOutput) then
      FOnMidiOutput(Self);
  end;
  { TODO: Case for MOM_PLAYBACK_DONE }
end;

procedure Register;
begin
  RegisterComponents('Piano Suite', [TMidiOutput]);
end;

end.

