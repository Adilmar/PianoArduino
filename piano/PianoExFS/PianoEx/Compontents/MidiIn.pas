unit MidiIn;

interface

uses
  Classes, SysUtils, WinTypes, Messages, WinProcs, MMSystem, MidiCommon;

type
  MidiInputState = (misOpen, misClosed, misCreating, misDestroying);
  EMidiInputError = class(Exception);

  TMidiInput = class(TComponent)
  private
    Handle: THandle; { Window handle used for callback notification }
    FDeviceID: Word; { MIDI device ID }
    FMIDIHandle: HMIDIIn; { Handle to input device }
    FState: MidiInputState; { Current device state }
    FError: Word;
    FSysexOnly: Boolean;
    { Stuff from MIDIINCAPS }
    FDriverVersion: Version;
    FProductName: string;
    FMID: Word; { Manufacturer ID }
    FPID: Word; { Product ID }
    { Queue }
    FCapacity: Word; { Buffer capacity }
    PBuffer: PCircularBuffer; { Low-level MIDI input buffer created by Open method }
    FNumdevs: Word; { Number of input devices on system }
    { Events }
    FOnMIDIInput: TNotifyEvent; { MIDI Input arrived }
    FOnOverflow: TNotifyEvent; { Input buffer overflow }
    { TODO: Some sort of error handling event for MIM_ERROR }
    { Sysex }
    FSysexBufferSize: Word;
    FSysexBufferCount: Word;
    MidiHdrs: Tlist;
    PCtlInfo: PMidiCtlInfo; { Pointer to control info for DLL }
  protected
    procedure Prepareheaders;
    procedure UnprepareHeaders;
    procedure AddBuffers;
    procedure SetDeviceID(DeviceID: Word);
    procedure SetProductName(NewProductName: string);
    function GetEventCount: Word;
    procedure SetSysexBufferSize(BufferSize: Word);
    procedure SetSysexBufferCount(BufferCount: Word);
    procedure SetSysexOnly(bSysexOnly: Boolean);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property MIDIHandle: HMIDIIn read FMIDIHandle;
    property DriverVersion: Version read FDriverVersion;
    property MID: Word read FMID; { Manufacturer ID }
    property PID: Word read FPID; { Product ID }
    property Numdevs: Word read FNumdevs;
    property MessageCount: Word read GetEventCount;
    { TODO: property to select which incoming messages get filtered out }
    procedure Open;
    procedure Close;
    procedure Start;
    procedure Stop;
    { Get first message in input queue }
    function GetMidiEvent: TMyMidiEvent;
    procedure MidiInput(var Message: TMessage);
    { Some functions to decode and classify incoming messages would be good }
  published
    { TODO: Property editor with dropdown list of product names }
    property ProductName: string read FProductName write SetProductName;
    property DeviceID: Word read FDeviceID write SetDeviceID default 0;
    property Capacity: Word read FCapacity write FCapacity default 1024;
    property Error: Word read FError;
    property SysexBufferSize: Word read FSysexBufferSize write SetSysexBufferSize default 10000;
    property SysexBufferCount: Word read FSysexBufferCount write SetSysexBufferCount default 16;
    property SysexOnly: Boolean read FSysexOnly write SetSysexOnly default False;
 { Events }
    property OnMidiInput: TNotifyEvent read FOnMidiInput write FOnMidiInput;
    property OnOverflow: TNotifyEvent read FOnOverflow write FOnOverflow;
  end;

procedure Register;

implementation

uses Graphics, Controls, Forms, Dialogs;

function CircbufAlloc(Capacity: Word): PCircularBuffer;
var
  NewCircularBuffer: PCircularBuffer;
  NewMIDIBuffer: PMidiBufferItem;
  hMem: HGLOBAL;
begin
  { TODO: Validate circbuf size, <64K }
  NewCircularBuffer := GlobalSharedLockedAlloc(Sizeof(TCircularBuffer), hMem);
  if (NewCircularBuffer <> nil) then
  begin
    NewCircularBuffer^.RecordHandle := hMem;
    NewMIDIBuffer := GlobalSharedLockedAlloc(Capacity * Sizeof(TMidiBufferItem), hMem);
    if (NewMIDIBuffer = nil) then
    begin
      { TODO: Exception here? }
      GlobalSharedLockedFree(NewCircularBuffer^.RecordHandle, NewCircularBuffer);
      NewCircularBuffer := nil;
    end else
    begin
      NewCircularBuffer^.pStart := NewMidiBuffer;
      { Point to item at end of buffer }
      NewCircularBuffer^.pEnd := NewMidiBuffer;
      Inc(NewCircularBuffer^.pEnd, Capacity);
      { Start off the get and put pointers in the same position.
        These will get out of sync as the interrupts start rolling in }
      NewCircularBuffer^.pNextPut := NewMidiBuffer;
      NewCircularBuffer^.pNextGet := NewMidiBuffer;
      NewCircularBuffer^.Error := 0;
      NewCircularBuffer^.Capacity := Capacity;
      NewCircularBuffer^.EventCount := 0;
    end;
  end;
  CircbufAlloc := NewCircularBuffer;
end;

procedure CircbufFree(pBuffer: PCircularBuffer);
begin
  if (pBuffer <> nil) then
  begin
    GlobalSharedLockedFree(pBuffer^.BufferHandle, pBuffer^.pStart);
    GlobalSharedLockedFree(pBuffer^.RecordHandle, pBuffer);
  end;
end;

function CircbufReadEvent(PBuffer: PCircularBuffer; PEvent: PMidiBufferItem): Boolean;
{ Reads first event in queue without removing it, False if no events in queue }
var
  PCurrentEvent: PMidiBufferItem;
begin
  if (PBuffer^.EventCount <= 0) then
    CircbufReadEvent := False else
  begin
    PCurrentEvent := PBuffer^.PNextget;
    { Copy the object from the "tail" of the buffer to the caller's object }
    PEvent^.Timestamp := PCurrentEvent^.Timestamp;
    PEvent^.Data := PCurrentEvent^.Data;
    PEvent^.Sysex := PCurrentEvent^.Sysex;
    CircbufReadEvent := True;
  end;
end;

function CircbufRemoveEvent(PBuffer: PCircularBuffer): Boolean;
{ Remove current event from the queue }
begin
  if (PBuffer^.EventCount > 0) then
  begin
    Dec(Pbuffer^.EventCount);
    { Advance the buffer pointer, with wrap }
    Inc(Pbuffer^.PNextGet);
    if (PBuffer^.PNextGet = PBuffer^.PEnd) then
      PBuffer^.PNextGet := PBuffer^.PStart;
    CircbufRemoveEvent := True;
  end else
    CircbufRemoveEvent := False;
end;

constructor TMidiInput.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FState := misCreating;
  FSysexOnly := False;
  FNumDevs := midiInGetNumDevs;
  MidiHdrs := nil;
  { Set defaults }
  if (FNumDevs > 0) then
    SetDeviceID(0);
  FCapacity := 1024;
  FSysexBufferSize := 4096;
  FSysexBufferCount := 16;
  { Create the window for callback notification }
  if not (csDesigning in ComponentState) then
  begin
    Handle := AllocateHwnd(MidiInput);
  end;
  FState := misClosed;
end;

destructor TMidiInput.Destroy;
{ Close the device if it's open }
begin
  if (FMidiHandle <> 0) then
  begin
    Close;
    FMidiHandle := 0;
  end;
  if (PCtlInfo <> nil) then
    GlobalSharedLockedFree(PCtlinfo^.hMem, PCtlInfo);
  DeallocateHwnd(Handle);
  inherited Destroy;
end;

procedure TMidiInput.SetSysexBufferSize(BufferSize: Word);
{ Set the sysex buffer size, fail if device is already open }
begin
  if FState = misOpen then
    raise EMidiInputError.Create('Change to SysexBufferSize while device was open')
  else
    { TODO: Validate the sysex buffer size. Is this necessary for WIN32? }
    FSysexBufferSize := BufferSize;
end;

procedure TMidiInput.SetSysexBuffercount(Buffercount: Word);
{ Set the sysex buffer count, fail if device is already open }
begin
  if FState = misOpen then
    raise EMidiInputError.Create('Change to SysexBuffercount while device was open')
  else
    { TODO: Validate the sysex buffer count }
    FSysexBuffercount := Buffercount;
end;

procedure TMidiInput.SetSysexOnly(bSysexOnly: Boolean);
{ Set the Sysex Only flag to eliminate unwanted short MIDI input messages }
begin
  FSysexOnly := bSysexOnly;
  { Update the interrupt handler's copy of this property }
  if PCtlInfo <> nil then
    PCtlInfo^.SysexOnly := bSysexOnly;
end;

procedure TMidiInput.SetDeviceID(DeviceID: Word);
{ Set the Device ID to select a new MIDI input device
  Note: If no MIDI devices are installed, throws an 'Invalid Device ID' exception }
var
  MidiInCaps: TMidiInCaps;
begin
  if FState = misOpen then
    raise EMidiInputError.Create('Change to DeviceID while device was open')
  else
    if (DeviceID >= midiInGetNumDevs) then
      raise EMidiInputError.Create('Invalid device ID') else
    begin
      FDeviceID := DeviceID;
      { Set the name and other MIDIINCAPS properties to match the ID }
      FError := midiInGetDevCaps(DeviceID, @MidiInCaps, sizeof(TMidiInCaps));
      if Ferror <> MMSYSERR_NOERROR then
        raise EMidiInputError.Create(MidiIOErrorString(True, FError));
      FProductName := StrPas(MidiInCaps.szPname);
      FDriverVersion := MidiInCaps.vDriverVersion;
      FMID := MidiInCaps.wMID;
      FPID := MidiInCaps.wPID;
    end;
end;

procedure TMidiInput.SetProductName(NewProductName: string);
{ Set the product name and put the matching input device number in FDeviceID }
var
  MidiInCaps: TMidiInCaps;
  testDeviceID: Word;
  testProductName: string;
begin
  if FState = misOpen then
    raise EMidiInputError.Create('Change to ProductName while device was open')
  else
    if not (csLoading in ComponentState) then
    begin
      for testDeviceID := 0 to (midiInGetNumDevs - 1) do
      begin
        FError := midiInGetDevCaps(testDeviceID, @MidiInCaps, sizeof(TMidiInCaps));
        if Ferror <> MMSYSERR_NOERROR then
          raise EMidiInputError.Create(MidiIOErrorString(True, FError));
        testProductName := StrPas(MidiInCaps.szPname);
        if testProductName = NewProductName then
        begin
          FProductName := NewProductName;
          Break;
        end;
      end;
      if FProductName <> NewProductName then
        raise EMidiInputError.Create('MIDI Input Device ' + NewProductName + ' not installed ') else
        SetDeviceID(testDeviceID);
    end;
end;

procedure TMidiInput.PrepareHeaders;
{ Get the sysex buffers ready }
var
  ctr: Word;
  MyMidiHdr: TMyMidiHdr;
begin
  if (FSysexBufferCount > 0) and (FSysexBufferSize > 0) and (FMidiHandle <> 0) then
  begin
    Midihdrs := TList.Create;
    for ctr := 1 to FSysexBufferCount do
    begin
      { Initialize the header and allocate buffer memory }
      MyMidiHdr := TMyMidiHdr.Create(FSysexBufferSize);
      { Store the address of the MyMidiHdr object in the contained MIDIHDR structure
        so we can get back to the object when a pointer to the MIDIHDR is received }
      MyMidiHdr.hdrPointer^.dwUser := DWORD(MyMidiHdr);
      { Get MMSYSTEM's blessing for this header }
      FError := midiInPrepareHeader(FMidiHandle, MyMidiHdr.hdrPointer, sizeof(TMIDIHDR));
      if Ferror <> MMSYSERR_NOERROR then
        raise EMidiInputError.Create(MidiIOErrorString(True, FError));
      { Save it in our list }
      MidiHdrs.Add(MyMidiHdr);
    end;
  end;
end;

procedure TMidiInput.UnprepareHeaders;
{ Clean up from PrepareHeaders }
var
  ctr: Word;
begin
  if (MidiHdrs <> nil) then { will be Nil if 0 sysex buffers }
  begin
    for ctr := 0 to MidiHdrs.Count - 1 do
    begin
      FError := midiInUnprepareHeader(
        FMidiHandle,
        TMyMidiHdr(MidiHdrs.Items[ctr]).hdrPointer,
        sizeof(TMIDIHDR));
      if Ferror <> MMSYSERR_NOERROR then
        raise EMidiInputError.Create(MidiIOErrorString(True, FError));
      TMyMidiHdr(MidiHdrs.Items[ctr]).Free;
    end;
    MidiHdrs.Free;
    MidiHdrs := nil;
  end;
end;

procedure TMidiInput.AddBuffers;
{ Add sysex buffers, if required, to input device }
var
  ctr: Word;
begin
  if MidiHdrs <> nil then { will be Nil if 0 sysex buffers }
  begin
    if MidiHdrs.Count > 0 then
    begin
      for ctr := 0 to MidiHdrs.Count - 1 do
      begin
        FError := midiInAddBuffer(FMidiHandle,
          TMyMidiHdr(MidiHdrs.Items[ctr]).hdrPointer,
          sizeof(TMIDIHDR));
        if FError <> MMSYSERR_NOERROR then
          raise EMidiInputError.Create(MidiIOErrorString(True, FError));
      end;
    end;
  end;
end;

procedure TMidiInput.Open;
var
  hMem: THandle;
begin
  try
    { Create the buffer for the MIDI input messages }
    if (PBuffer = nil) then
      PBuffer := CircBufAlloc(FCapacity);
    { Create the control info for the DLL }
    if (PCtlInfo = nil) then
    begin
      PCtlInfo := GlobalSharedLockedAlloc(Sizeof(TMidiCtlInfo), hMem);
      PctlInfo^.hMem := hMem;
    end;
    PctlInfo^.pBuffer := PBuffer;
    Pctlinfo^.hWindow := Handle; { Control's window handle }
    PCtlInfo^.SysexOnly := FSysexOnly;
    FError := midiInOpen(
      @FMidiHandle,
      FDeviceId,
      DWORD(@midiHandler),
      DWORD(PCtlInfo),
      CALLBACK_FUNCTION);
    if (FError <> MMSYSERR_NOERROR) then
      { TODO: use CreateFmtHelp to add MIDI device name/ID to message }
      raise EMidiInputError.Create(MidiIOErrorString(True, FError));
    { Get sysex buffers ready }
    PrepareHeaders;
    { Add them to the input }
    AddBuffers;
    FState := misOpen;
  except
    if PBuffer <> nil then
    begin
      CircBufFree(PBuffer);
      PBuffer := nil;
    end;
    if PCtlInfo <> nil then
    begin
      GlobalSharedLockedFree(PCtlInfo^.hMem, PCtlInfo);
      PCtlInfo := nil;
    end;
  end;
end;

function TMidiInput.GetMidiEvent: TMyMidiEvent;
var
  thisItem: TMidiBufferItem;
begin
  if (FState = misOpen) and CircBufReadEvent(PBuffer, @thisItem) then
  begin
    Result := TMyMidiEvent.Create;
    with thisItem do
    begin
      Result.Time := Timestamp;
      if (Sysex = nil) then
      begin { Short message }
        Result.MidiMessage := LoByte(LoWord(Data));
        Result.Data1 := HiByte(LoWord(Data));
        Result.Data2 := LoByte(HiWord(Data));
        Result.Sysex := nil;
        Result.SysexLength := 0;
      end else { Long Sysex message }
      begin
        Result.MidiMessage := MIDI_BEGINSYSEX;
        Result.Data1 := 0;
        Result.Data2 := 0;
        Result.SysexLength := Sysex^.dwBytesRecorded;
        if Sysex^.dwBytesRecorded <> 0 then
        begin
          { Put a copy of the sysex buffer in the object }
          GetMem(Result.Sysex, Sysex^.dwBytesRecorded);
          StrMove(Result.Sysex, Sysex^.lpData, Sysex^.dwBytesRecorded);
        end;
        { Put the header back on the input buffer }
        FError := midiInPrepareHeader(FMidiHandle, Sysex, sizeof(TMIDIHDR));
        if Ferror = 0 then
          FError := midiInAddBuffer(FMidiHandle, Sysex, sizeof(TMIDIHDR));
        if Ferror <> MMSYSERR_NOERROR then
          raise EMidiInputError.Create(MidiIOErrorString(True, FError));
      end;
    end;
    CircbufRemoveEvent(PBuffer);
  end else
    { Device isn't open, return a nil event }
    Result := nil;
end;

function TMidiInput.GetEventCount: Word;
begin
  if FState = misOpen then
    Result := PBuffer^.EventCount
  else
    Result := 0;
end;

procedure TMidiInput.Close;
begin
  if FState = misOpen then
  begin
    FState := misClosed;
    { MidiInReset cancels any pending output }
    FError := MidiInReset(FMidiHandle);
    if Ferror <> MMSYSERR_NOERROR then
      raise EMidiInputError.Create(MidiIOErrorString(True, FError));
    { Remove sysex buffers from input device and free them }
    UnPrepareHeaders;
    { Close the device (finally!) }
    FError := MidiInClose(FMidiHandle);
    if Ferror <> MMSYSERR_NOERROR then
      raise EMidiInputError.Create(MidiIOErrorString(True, FError));
    FMidiHandle := 0;
    if (PBuffer <> nil) then
    begin
      CircBufFree(PBuffer);
      PBuffer := nil;
    end;
  end;
end;

procedure TMidiInput.Start;
begin
  if FState = misOpen then
  begin
    FError := MidiInStart(FMidiHandle);
    if Ferror <> MMSYSERR_NOERROR then
      raise EMidiInputError.Create(MidiIOErrorString(True, FError));
  end;
end;

procedure TMidiInput.Stop;
begin
  if FState = misOpen then
  begin
    FError := MidiInStop(FMidiHandle);
    if Ferror <> MMSYSERR_NOERROR then
      raise EMidiInputError.Create(MidiIOErrorString(True, FError));
  end;
end;

procedure TMidiInput.MidiInput(var Message: TMessage);
{ Triggered by incoming message from DLL.
  Note DLL has already put the message in the queue }
begin
  case Message.Msg of
    mim_data:
      { Trigger the user's MIDI input event }
      if Assigned(FOnMIDIInput) and (FState = misOpen) and (GetEventCount > 0) then
        FOnMIDIInput(Self);
    mim_Overflow:
      { input circular buffer overflow }
      if Assigned(FOnOverflow) and (FState = misOpen) then
        FOnOverflow(Self);
  end;
end;

procedure Register;
begin
  RegisterComponents('Piano Suite', [TMIDIInput]);
end;

end.

