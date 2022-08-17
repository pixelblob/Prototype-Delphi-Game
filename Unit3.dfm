object Form3: TForm3
  Left = 411
  Top = 231
  BorderIcons = [biSystemMenu, biMinimize, biHelp]
  BorderStyle = bsSingle
  Caption = 'Form3'
  ClientHeight = 640
  ClientWidth = 1280
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  HelpFile = 'Help.chm'
  OldCreateOrder = False
  Position = poDesigned
  OnCreate = FormCreate
  OnKeyDown = FormKeyDown
  OnKeyUp = FormKeyUp
  PixelsPerInch = 96
  TextHeight = 13
  object Image1: TImage
    Left = 0
    Top = 0
    Width = 105
    Height = 105
    OnClick = Image1Click
  end
  object LevelImage: TImage
    Left = 336
    Top = 88
    Width = 105
    Height = 105
    Visible = False
  end
  object warning: TLabel
    Left = 320
    Top = 256
    Width = 640
    Height = 78
    Caption = 
      'Pausing the so your eyes dont have to experience my game flashin' +
      'g like hell'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWhite
    Font.Height = -32
    Font.Name = 'Tahoma'
    Font.Style = [fsBold, fsUnderline]
    ParentFont = False
    WordWrap = True
  end
  object gameLoop: TTimer
    Interval = 1
    OnTimer = gameLoopTimer
    Left = 600
    Top = 8
  end
  object FpsReset: TTimer
    OnTimer = FpsResetTimer
    Left = 1024
    Top = 384
  end
  object screenBlankTimer: TTimer
    Interval = 250
    OnTimer = screenBlankTimerTimer
    Left = 608
    Top = 464
  end
end
