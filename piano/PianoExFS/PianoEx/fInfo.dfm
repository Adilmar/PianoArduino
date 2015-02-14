object frmInfo: TfrmInfo
  Left = 363
  Top = 321
  Width = 534
  Height = 356
  BorderWidth = 6
  Caption = 'Midi Information'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  OnCreate = FormCreate
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object GroupBox1: TGroupBox
    Left = 0
    Top = 0
    Width = 514
    Height = 89
    Align = alTop
    Caption = 'Header'
    TabOrder = 0
    object rgFileType: TRadioGroup
      Left = 16
      Top = 24
      Width = 257
      Height = 49
      Caption = 'File Type'
      Columns = 3
      Items.Strings = (
        'Single'
        'MultiSynch'
        'MultiAsynch')
      TabOrder = 0
    end
    object LabeledEdit1: TLabeledEdit
      Left = 288
      Top = 48
      Width = 97
      Height = 21
      Color = clGrayText
      EditLabel.Width = 85
      EditLabel.Height = 13
      EditLabel.Caption = 'Number of Tracks'
      ReadOnly = True
      TabOrder = 1
    end
    object LabeledEdit2: TLabeledEdit
      Left = 400
      Top = 48
      Width = 97
      Height = 21
      EditLabel.Width = 88
      EditLabel.Height = 13
      EditLabel.Caption = 'Pulses Per Quarter'
      TabOrder = 2
    end
  end
  object GroupBox2: TGroupBox
    Left = 0
    Top = 89
    Width = 514
    Height = 221
    Align = alClient
    Caption = 'Tracks'
    TabOrder = 1
    object PageControl1: TPageControl
      Left = 2
      Top = 15
      Width = 510
      Height = 204
      Align = alClient
      MultiLine = True
      ScrollOpposite = True
      TabOrder = 0
    end
  end
  object Timer1: TTimer
    OnTimer = Timer1Timer
    Left = 344
    Top = 16
  end
end
