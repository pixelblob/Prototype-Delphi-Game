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
    Left = 48
    Top = 64
    Width = 105
    Height = 105
    OnClick = Image1Click
  end
  object LevelImage: TImage
    Left = 368
    Top = 112
    Width = 105
    Height = 105
    Visible = False
  end
  object cachedLevel: TImage
    Left = 320
    Top = 344
    Width = 105
    Height = 105
    Visible = False
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
end
