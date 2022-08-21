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
  OnClose = FormClose
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
    OnMouseDown = Image1MouseDown
    OnMouseUp = Image1MouseUp
  end
  object LevelImage: TImage
    Left = 0
    Top = 136
    Width = 105
    Height = 105
    Visible = False
  end
  object cachedLevel: TImage
    Left = 0
    Top = 272
    Width = 105
    Height = 105
    Visible = False
  end
  object brightnessMap: TImage
    Left = 0
    Top = 408
    Width = 105
    Height = 105
    Visible = False
  end
  object gameLoop: TTimer
    Interval = 1
    OnTimer = gameLoopTimer
    Left = 184
    Top = 24
  end
  object FpsReset: TTimer
    OnTimer = FpsResetTimer
    Left = 184
    Top = 168
  end
end
