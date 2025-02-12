object Form5: TForm5
  Left = 0
  Top = 0
  Caption = 'Form5'
  ClientHeight = 549
  ClientWidth = 1021
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  OnMouseWheel = FormMouseWheel
  TextHeight = 15
  object PaintBox: TPaintBox
    Left = 0
    Top = 50
    Width = 1021
    Height = 499
    Align = alClient
    OnMouseDown = PaintBoxMouseDown
    OnMouseMove = PaintBoxMouseMove
    OnMouseUp = PaintBoxMouseUp
    OnPaint = PaintBoxPaint
    ExplicitTop = 56
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 1021
    Height = 50
    Align = alTop
    TabOrder = 0
  end
  object btnRectangle: TButton
    Left = 120
    Top = 8
    Width = 97
    Height = 25
    Caption = 'Rectangle'
    TabOrder = 1
    OnClick = btnRectangleClick
  end
  object btnCircle: TButton
    Left = 232
    Top = 8
    Width = 75
    Height = 25
    Caption = 'Circle'
    TabOrder = 2
    OnClick = btnCircleClick
  end
  object btnLine: TButton
    Left = 32
    Top = 8
    Width = 75
    Height = 25
    Caption = 'Line'
    TabOrder = 3
    OnClick = btnLineClick
  end
  object cmbLineWidth: TComboBox
    Left = 487
    Top = 8
    Width = 145
    Height = 23
    Color = clBtnFace
    TabOrder = 4
    Text = 'cmbLineWidth'
    OnChange = cmbLineWidthChange
  end
  object ColorBox: TColorBox
    Left = 336
    Top = 8
    Width = 145
    Height = 22
    Style = [cbStandardColors, cbExtendedColors, cbCustomColor]
    TabOrder = 5
    OnChange = ColorBoxChange
  end
  object btnSelection: TButton
    Left = 648
    Top = 8
    Width = 75
    Height = 25
    Caption = 'Selection'
    TabOrder = 6
    OnClick = btnSelectionClick
  end
end
