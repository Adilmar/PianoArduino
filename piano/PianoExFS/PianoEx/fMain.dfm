object frmMain: TfrmMain
  Left = 274
  Top = 266
  BorderStyle = bsSingle
  Caption = 'PianoEx v1.1 (MidiFile Player)'
  ClientHeight = 332
  ClientWidth = 757
  Color = clBtnFace
  Font.Charset = ANSI_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyDown = FormKeyDown
  OnKeyUp = FormKeyUp
  OnShortCut = FormShortCut
  DesignSize = (
    757
    332)
  PixelsPerInch = 96
  TextHeight = 13
  object Label8: TLabel
    Left = 352
    Top = 8
    Width = 89
    Height = 13
    Caption = 'www.PianoEx.com'
    Font.Charset = ANSI_CHARSET
    Font.Color = clBlue
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
  end
  object btnOpen: TBitBtn
    Left = 344
    Top = 32
    Width = 57
    Height = 25
    Action = actOpen
    Caption = 'Open'
    TabOrder = 0
  end
  object btnPlay: TBitBtn
    Left = 400
    Top = 32
    Width = 57
    Height = 25
    Action = actPlay
    Caption = 'Play'
    TabOrder = 1
  end
  object PageControl1: TPageControl
    Left = 472
    Top = 8
    Width = 273
    Height = 153
    ActivePage = tsTrack
    Anchors = [akLeft, akTop, akRight]
    Style = tsButtons
    TabOrder = 3
    object tsTrack: TTabSheet
      Caption = 'Track'
      ImageIndex = 1
      object PianoTracks1: TPianoTracks
        Left = 0
        Top = 0
        Width = 265
        Height = 122
        LeftCaption = 'Left'
        RightCaption = 'Right'
        OnTrackClick = PianoTracks1TrackClick
        Align = alClient
        Caption = 'PianoTracks1'
      end
    end
    object TabSheet1: TTabSheet
      Caption = 'Event'
      ImageIndex = 2
      object lstEvent: TListBox
        Left = 0
        Top = 0
        Width = 265
        Height = 122
        Align = alClient
        ItemHeight = 13
        TabOrder = 0
      end
    end
  end
  object PageControl2: TPageControl
    Left = 16
    Top = 8
    Width = 313
    Height = 145
    ActivePage = tsCommon
    Style = tsButtons
    TabOrder = 4
    object tsCommon: TTabSheet
      Caption = 'Common'
      ImageIndex = 2
      object Label1: TLabel
        Left = 40
        Top = 40
        Width = 42
        Height = 13
        Caption = 'Midi Out:'
      end
      object Label2: TLabel
        Left = 40
        Top = 64
        Width = 38
        Height = 13
        Caption = 'Octave:'
      end
      object Label3: TLabel
        Left = 152
        Top = 64
        Width = 32
        Height = 13
        Caption = 'Group:'
      end
      object Label4: TLabel
        Left = 40
        Top = 88
        Width = 34
        Height = 13
        Caption = 'Speed:'
      end
      object Label5: TLabel
        Left = 152
        Top = 88
        Width = 26
        Height = 13
        Caption = 'Time:'
      end
      object Label6: TLabel
        Left = 0
        Top = 88
        Width = 35
        Height = 13
        Caption = 'Volume'
      end
      object Label7: TLabel
        Left = 40
        Top = 16
        Width = 34
        Height = 13
        Caption = 'Midi In:'
      end
      object cbKeysGroupCount: TComboBox
        Left = 192
        Top = 56
        Width = 41
        Height = 21
        Style = csDropDownList
        ItemHeight = 13
        TabOrder = 0
        OnChange = cbKeysGroupCountChange
        Items.Strings = (
          '5'
          '6'
          '7'
          '8')
      end
      object trbOctave: TTrackBar
        Left = 82
        Top = 56
        Width = 61
        Height = 21
        Max = 6
        TabOrder = 1
        ThumbLength = 15
        OnChange = trbOctaveChange
      end
      object cbOutput: TComboBox
        Left = 88
        Top = 32
        Width = 217
        Height = 21
        Style = csDropDownList
        ItemHeight = 13
        TabOrder = 2
        OnChange = cbOutputChange
      end
      object edtSpeed: TEdit
        Left = 88
        Top = 80
        Width = 33
        Height = 21
        ReadOnly = True
        TabOrder = 3
        Text = '0'
      end
      object edtTime: TEdit
        Left = 192
        Top = 80
        Width = 113
        Height = 21
        TabOrder = 4
        Text = '0:00:00.000'
      end
      object trbVolume: TTrackBar
        Left = 0
        Top = 8
        Width = 25
        Height = 81
        Orientation = trVertical
        TabOrder = 5
        ThumbLength = 15
        OnChange = trbVolumeChange
      end
      object UpDown1: TUpDown
        Left = 121
        Top = 80
        Width = 16
        Height = 21
        Associate = edtSpeed
        Max = 250
        TabOrder = 6
        OnChanging = UpDown1Changing
      end
      object cbInput: TComboBox
        Left = 88
        Top = 8
        Width = 217
        Height = 21
        Style = csDropDownList
        ItemHeight = 13
        TabOrder = 7
        OnChange = cbOutputChange
      end
      object cbbColor: TComboBox
        Left = 240
        Top = 56
        Width = 65
        Height = 21
        Style = csDropDownList
        ItemHeight = 13
        TabOrder = 8
        OnChange = cbbColorChange
        Items.Strings = (
          'Black'
          'Blue'
          'Red'
          'Green')
      end
    end
    object tsChannel: TTabSheet
      Caption = 'Channel'
      ImageIndex = 1
      object PianoChannels1: TPianoChannels
        Left = 0
        Top = 0
        Width = 305
        Height = 114
        ChannelHeight = 60
        OnChannelClick = PianoChannels1ChannelClick
        Align = alClient
        BevelOuter = bvNone
      end
    end
  end
  object PianoKeyboard1: TPianoKeyboard
    Left = 16
    Top = 160
    Width = 724
    Height = 145
    GroupFontColor = clBlack
    PianoColor = pcGreen
    OnKeyboard = PianoKeyboard1Keyboard
    Color = clBtnFace
  end
  object btnStop: TBitBtn
    Left = 344
    Top = 64
    Width = 57
    Height = 25
    Action = actStop
    Caption = 'Stop'
    TabOrder = 2
  end
  object btnReset: TBitBtn
    Left = 400
    Top = 64
    Width = 57
    Height = 25
    Action = actReset
    Caption = 'Reset'
    TabOrder = 6
  end
  object btnExit: TBitBtn
    Left = 344
    Top = 128
    Width = 113
    Height = 25
    Action = actExit
    Caption = 'Exit'
    TabOrder = 5
  end
  object pbLength: TProgressBar
    Left = 0
    Top = 315
    Width = 757
    Height = 17
    Cursor = crHandPoint
    Align = alBottom
    Smooth = True
    TabOrder = 8
    OnMouseDown = pbLengthMouseDown
  end
  object BitBtn1: TBitBtn
    Left = 344
    Top = 96
    Width = 113
    Height = 25
    Action = actInfo
    Caption = 'Midi Infomation'
    TabOrder = 9
  end
  object MidiOutput1: TMidiOutput
    Left = 480
    Top = 48
  end
  object OpenDialog1: TOpenDialog
    Filter = 'Midi files(*.mid;*.midi)|*.mid;*.midi'
    Left = 480
    Top = 80
  end
  object ActionList1: TActionList
    Left = 512
    Top = 80
    object actStop: TAction
      Caption = 'Stop'
      OnExecute = actStopExecute
    end
    object actPlay: TAction
      Caption = 'Play'
      OnExecute = actPlayExecute
    end
    object actOpen: TAction
      Caption = 'Open'
      OnExecute = actOpenExecute
    end
    object actReset: TAction
      Caption = 'Reset'
      OnExecute = actResetExecute
    end
    object actExit: TAction
      Caption = 'Exit'
      OnExecute = actExitExecute
    end
    object actRecord: TAction
      Caption = 'Record'
      OnExecute = actRecordExecute
    end
    object actInfo: TAction
      Caption = 'Midi Infomation'
      OnExecute = actInfoExecute
    end
  end
  object MidiInput1: TMidiInput
    ProductName = 'Creative Sound Blaster MPU-401'
    SysexBufferSize = 4096
    OnMidiInput = MidiInput1MidiInput
    Left = 544
    Top = 48
  end
  object MidiPlayer1: TMidiPlayer
    MidiFile = MidiFile1
    Speed = 100
    CurrentTime = 0
    OnMidiEvent = MidiPlayer1MidiEvent
    OnSpeedChange = MidiPlayer1SpeedChange
    OnUpdateEvent = MidiPlayer1UpdateEvent
    OnReadyEvent = MidiPlayer1ReadyEvent
    Left = 576
    Top = 48
  end
  object MidiFile1: TMidiFile
    Left = 512
    Top = 48
  end
end
