unit Unit5;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, Generics.Collections, Math;

type
  T2DPoint = record
    X, Y: Single;
    class operator Subtract(const p1, p2: T2DPoint): T2DPoint;
    class operator Multiply(const d: double; const p: T2DPoint): T2DPoint;
    function Length: double;
    constructor Create(const x, y: double);
  end;

  ICanvas = interface
    procedure SetCurrentColor(c: TColor);
    procedure SetCurrentLineWidth(lw: Integer);
    procedure BeginDraw;
    procedure EndDraw;
    procedure MoveTo(const x, y: Single);
    procedure LineTo(const x, y: Single);
    procedure AddVertex(const p: T2DPoint);
  end;

  TShape = class
  public
    Color: TColor;
    LineWidth: Integer;
    IsSelected: Boolean;
    procedure Draw(const c: ICanvas); virtual; abstract;
    function IsPointInside(const x, y, tol: Single): Boolean; virtual; abstract;
    procedure MoveTo(const dx, dy: Single); virtual; abstract;
  end;

  TLine = class(TShape)
  public
    P1, P2: T2DPoint;
    procedure Draw(const c: ICanvas); override;
    function IsPointInside(const x, y, tol: Single): Boolean; override;
    procedure MoveTo(const dx, dy: Single); override;
  end;

  TRectangle = class(TShape)
  public
    P1, P2: T2DPoint;
    procedure Draw(const c: ICanvas); override;
    function IsPointInside(const x, y, tol: Single): Boolean; override;
    procedure MoveTo(const dx, dy: Single); override;
  end;

  TCircle = class(TShape)
  public
    Center: T2DPoint;
    Radius: Single;
    procedure Draw(const c: ICanvas); override;
    function IsPointInside(const x, y, tol: Single): Boolean; override;
    procedure MoveTo(const dx, dy: Single); override;
  end;

  TCanvasAdapter = class(TInterfacedObject, ICanvas)
  private
    FCanvas: TCanvas;
    fIsStarted: Boolean;
    fxmin, fymin, fxmax, fymax: Single;
    fLockedStyle: boolean;
    procedure SetBounds(const xmin, ymin, xmax, ymax: Single);
    function GetWidth: Integer;
    function GetHeight: Integer;
    function GetScaleFactor: double;
  public
    constructor Create(ACanvas: TCanvas);
    procedure SetCurrentColor(c: TColor);
    procedure SetCurrentLineWidth(lw: Integer);
    procedure BeginDraw;
    procedure EndDraw;
    procedure MoveTo(const x, y: Single);
    procedure LineTo(const x, y: Single);
    procedure AddVertex(const p: T2DPoint);
    procedure DrawRectangle(const x1, y1, x2, y2: Integer);
    procedure DrawEllipse(const x1, y1, x2, y2: Integer);
    function PointToPixel(const p: T2DPoint): TPoint;
    function PixelToPoint(const p: TPoint): T2DPoint;
    function GetCanvas: TCanvas;
    property xmin: single read fxmin write fxmin;
    property ymin: single read fymin write fymin;
    property xmax: single read fxmax write fxmax;
    property ymax: single read fymax write fymax;
    property LockedStyle: boolean read fLockedStyle write fLockedStyle;
    property ScaleFactor: double read GetScaleFactor;
  end;

  TTool = (ttLine, ttRectangle, ttCircle, ttSelection);

  TForm5 = class(TForm)
    Panel1: TPanel;
    btnRectangle: TButton;
    btnCircle: TButton;
    btnLine: TButton;
    btnSelection: TButton;
    cmbLineWidth: TComboBox;
    PaintBox: TPaintBox;
    ColorBox: TColorBox;
    btnSave: TButton;
    btnLoad: TButton;
    dlgOpen1: TOpenDialog;
    dlgSave1: TSaveDialog;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnLineClick(Sender: TObject);
    procedure btnRectangleClick(Sender: TObject);
    procedure btnCircleClick(Sender: TObject);
    procedure btnSelectionClick(Sender: TObject);
    procedure cmbLineWidthChange(Sender: TObject);
    procedure PaintBoxMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure PaintBoxMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure PaintBoxMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure PaintBoxPaint(Sender: TObject);
    procedure ColorBoxChange(Sender: TObject);
    procedure PaintBoxMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure FormMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure btnSaveClick(Sender: TObject);
    procedure btnLoadClick(Sender: TObject);
  private
    Shapes: TObjectList<TShape>;
    SelectedShapes: TList<TShape>;
    CurrentTool: TTool;
    SelectedColor: TColor;
    LineWidth: Integer;
    IsDrawing: Boolean;
    IsSelecting: Boolean;
    StartPoint, EndPoint: T2DPoint;
    ZoomFactor: Single;
    PanOffset: T2DPoint;
    IsPanning: Boolean;
    StartPanPoint: T2DPoint;
    fCanvas: TCanvasAdapter;
    procedure DrawTemporaryShape(CanvasAdapter: TCanvasAdapter);
    procedure MoveSelectedObject(const dx, dy: Single);
    procedure SelectObject(const x, y: Single; AddToSelection: Boolean);
  public
  end;

  function PointLineDist(const p, p1, p2: T2DPoint): double;
  function Dot(const p1, p2: T2DPoint): double;

var
  Form5: TForm5;

implementation

{$R *.dfm}

function Dot(const p1, p2: T2DPoint): double;
begin
  result := p1.x*p2.x+p1.y*p2.y;
end;

function PointLineDist(const p, p1, p2: T2DPoint): double;
begin
  var v1 := p2-p1;
  var v2 := p-p1;
  var L1 := v1.Length;
  v1 := 1/L1*v1;
  var x := Dot(v1, v2);
  if (x<0) then begin
    result := v2.Length;
  end else if (x>L1) then begin
    result := (p-p2).Length;
  end else begin
    result := (v2-x*v1).Length;
  end;
end;

{ TCanvasAdapter }

constructor TCanvasAdapter.Create(ACanvas: TCanvas);
begin
  inherited Create;
  FCanvas := ACanvas;
  fIsStarted := False;
  SetBounds(0, 0, FCanvas.ClipRect.Width, FCanvas.ClipRect.Height);
end;

procedure TCanvasAdapter.SetBounds(const xmin, ymin, xmax, ymax: Single);
begin
  fxmin := xmin;
  fymin := ymin;
  fxmax := xmax;
  fymax := ymax;
end;

procedure TCanvasAdapter.SetCurrentColor(c: TColor);
begin
  if fLockedStyle then
    exit;
  if FCanvas <> nil then
    FCanvas.Pen.Color := c;
end;

procedure TCanvasAdapter.SetCurrentLineWidth(lw: Integer);
begin
  if fLockedStyle then
    exit;
  if FCanvas <> nil then
    FCanvas.Pen.Width := lw;
end;

procedure TCanvasAdapter.BeginDraw;
begin
  fIsStarted := False;
end;

procedure TCanvasAdapter.EndDraw;
begin
  fIsStarted := False;
end;

procedure TCanvasAdapter.MoveTo(const x, y: Single);
var
  pp: TPoint;
begin
  pp := PointToPixel(T2DPoint.Create(x, y));
  FCanvas.MoveTo(pp.X, pp.Y);
end;

procedure TCanvasAdapter.LineTo(const x, y: Single);
var
  pp: TPoint;
begin
  pp := PointToPixel(T2DPoint.Create(x, y));
  FCanvas.LineTo(pp.X, pp.Y);
end;

procedure TCanvasAdapter.AddVertex(const p: T2DPoint);
var
  pp: TPoint;
begin
  pp := PointToPixel(p);
  if fIsStarted then
    FCanvas.LineTo(pp.X, pp.Y)
  else
  begin
    FCanvas.MoveTo(pp.X, pp.Y);
    fIsStarted := True;
  end;
end;

procedure TCanvasAdapter.DrawRectangle(const x1, y1, x2, y2: Integer);
begin
  FCanvas.Rectangle(x1, y1, x2, y2);
end;

procedure TCanvasAdapter.DrawEllipse(const x1, y1, x2, y2: Integer);
begin
  FCanvas.Ellipse(x1, y1, x2, y2);
end;

function TCanvasAdapter.PointToPixel(const p: T2DPoint): TPoint;
begin
  Result.X := Round((p.X - fxmin) / (fxmax - fxmin) * GetWidth);
  Result.Y := Round(GetHeight - ((p.Y - fymin) / (fymax - fymin) * GetHeight));
end;

function TCanvasAdapter.PixelToPoint(const p: TPoint): T2DPoint;
begin
  Result.X := fxmin + (p.X / GetWidth) * (fxmax - fxmin);
  Result.Y := fymin + ((GetHeight - p.Y) / GetHeight) * (fymax - fymin);
end;

function TCanvasAdapter.GetWidth: Integer;
begin
  Result := FCanvas.ClipRect.Width;
end;

function TCanvasAdapter.GetHeight: Integer;
begin
  Result := FCanvas.ClipRect.Height;
end;

function TCanvasAdapter.GetScaleFactor: double;
begin
  result := (fxmax-fxmin)/self.GetWidth;
end;

function TCanvasAdapter.GetCanvas: TCanvas;
begin
  Result := FCanvas;
end;

{ TLine }

procedure TLine.Draw(const c: ICanvas);
begin
  c.SetCurrentColor(Color);
  c.SetCurrentLineWidth(LineWidth);
  c.BeginDraw;
  c.MoveTo(P1.X, P1.Y);
  c.LineTo(P2.X, P2.Y);
  c.EndDraw;
end;

function TLine.IsPointInside(const x, y, tol: Single): Boolean;
var
  d: Single;
begin
  d := PointLineDist(T2DPoint.Create(x, y), self.P1, self.P2);
  result := d<tol;
end;

procedure TLine.MoveTo(const dx, dy: Single);
begin
  P1.X := P1.X + dx;
  P1.Y := P1.Y + dy;
  P2.X := P2.X + dx;
  P2.Y := P2.Y + dy;
end;

{ TRectangle }

procedure TRectangle.Draw(const c: ICanvas);
begin
  c.SetCurrentColor(Color);
  c.SetCurrentLineWidth(LineWidth);
  c.BeginDraw;
  c.MoveTo(P1.X, P1.Y);
  c.LineTo(P2.X, P1.Y);
  c.LineTo(P2.X, P2.Y);
  c.LineTo(P1.X, P2.Y);
  c.LineTo(P1.X, P1.Y);
  c.EndDraw;
end;

function TRectangle.IsPointInside(const x, y, tol: Single): Boolean;
var
  min_x, max_x, min_y, max_y: Single;
begin
  min_x := Min(P1.X, P2.X) - LineWidth / 2;
  max_x := Max(P1.X, P2.X) + LineWidth / 2;
  min_y := Min(P1.Y, P2.Y) - LineWidth / 2;
  max_y := Max(P1.Y, P2.Y) + LineWidth / 2;
  Result := (x >= min_x) and (x <= max_x) and
            (y >= min_y) and (y <= max_y);
end;

procedure TRectangle.MoveTo(const dx, dy: Single);
begin
  P1.X := P1.X + dx;
  P1.Y := P1.Y + dy;
  P2.X := P2.X + dx;
  P2.Y := P2.Y + dy;
end;

{ TCircle }

procedure TCircle.Draw(const c: ICanvas);
begin
  c.SetCurrentColor(Color);
  c.SetCurrentLineWidth(LineWidth);
  c.BeginDraw;
  const n=64;
  for var i := 0 to n do begin
    var a := i*2*Pi/n;
    c.AddVertex(T2DPoint.Create(Center.x+cos(a)*Radius, Center.y+sin(a)*Radius));
  end;
  c.EndDraw;
end;

function TCircle.IsPointInside(const x, y, tol: Single): Boolean;
begin
  var d := (T2DPoint.Create(x,y)-Center).Length-Radius;
  result := abs(d)<Tol;
end;

procedure TCircle.MoveTo(const dx, dy: Single);
begin
  Center.X := Center.X + dx;
  Center.Y := Center.Y + dy;
end;

{ TForm5 }

procedure TForm5.FormCreate(Sender: TObject);
begin
  Shapes := TObjectList<TShape>.Create;
  SelectedShapes := TList<TShape>.Create;
  SelectedColor := clBlack;
  LineWidth := 1;
  ZoomFactor := 1.0;
  PanOffset.X := 0;
  PanOffset.Y := 0;
  IsPanning := False;
  self.doubleBuffered := true;

  cmbLineWidth.Items.AddStrings(['1', '2', '3', '4', '5']);
  cmbLineWidth.ItemIndex := 0;

  ColorBox.Selected := clBlack;
  fCanvas := TCanvasAdapter.Create(PaintBox.Canvas);
  fCanvas.SetBounds(0, 0, PaintBox.Width, PaintBox.Height);

  // Настройка диалогов
  dlgOpen1.Filter := 'Vector Graphics|*.vgf|All Files|*.*';
  dlgSave1.Filter := 'Vector Graphics|*.vgf|All Files|*.*';
  dlgOpen1.DefaultExt := 'vgf';
  dlgSave1.DefaultExt := 'vgf';
end;

procedure TForm5.FormDestroy(Sender: TObject);
begin
  Shapes.Free;
  SelectedShapes.Free;
end;

procedure TForm5.btnSaveClick(Sender: TObject);
var
  Stream: TFileStream;
  Writer: TWriter;
  Shape: TShape;
begin
  if dlgSave1.Execute then
  begin
    Stream := TFileStream.Create(dlgSave1.FileName, fmCreate);
    try
      Writer := TWriter.Create(Stream, 4096);
      try
        Writer.WriteListBegin;
        for Shape in Shapes do
        begin
          if Shape is TLine then
          begin
            Writer.WriteString('Line');
            Writer.WriteInteger(Shape.Color);
            Writer.WriteInteger(Shape.LineWidth);
            Writer.WriteFloat(TLine(Shape).P1.X);
            Writer.WriteFloat(TLine(Shape).P1.Y);
            Writer.WriteFloat(TLine(Shape).P2.X);
            Writer.WriteFloat(TLine(Shape).P2.Y);
          end
          else if Shape is TRectangle then
          begin
            Writer.WriteString('Rectangle');
            Writer.WriteInteger(Shape.Color);
            Writer.WriteInteger(Shape.LineWidth);
            Writer.WriteFloat(TRectangle(Shape).P1.X);
            Writer.WriteFloat(TRectangle(Shape).P1.Y);
            Writer.WriteFloat(TRectangle(Shape).P2.X);
            Writer.WriteFloat(TRectangle(Shape).P2.Y);
          end
          else if Shape is TCircle then
          begin
            Writer.WriteString('Circle');
            Writer.WriteInteger(Shape.Color);
            Writer.WriteInteger(Shape.LineWidth);
            Writer.WriteFloat(TCircle(Shape).Center.X);
            Writer.WriteFloat(TCircle(Shape).Center.Y);
            Writer.WriteFloat(TCircle(Shape).Radius);
          end;
        end;
        Writer.WriteListEnd;
      finally
        Writer.Free;
      end;
    finally
      Stream.Free;
    end;
  end;
end;

procedure TForm5.btnLoadClick(Sender: TObject);
var
  Stream: TFileStream;
  Reader: TReader;
  ShapeType: string;
  Color: TColor;
  LineWidth: Integer;
begin
  if dlgOpen1.Execute then
  begin
    Stream := TFileStream.Create(dlgOpen1.FileName, fmOpenRead);
    try
      Reader := TReader.Create(Stream, 4096);
      try
        Reader.ReadListBegin;
        Shapes.Clear;
        SelectedShapes.Clear;
        while not Reader.EndOfList do
        begin
          ShapeType := Reader.ReadString;
          Color := Reader.ReadInteger;
          LineWidth := Reader.ReadInteger;

          if ShapeType = 'Line' then
          begin
            var Line := TLine.Create;
            Line.P1.X := Reader.ReadFloat;
            Line.P1.Y := Reader.ReadFloat;
            Line.P2.X := Reader.ReadFloat;
            Line.P2.Y := Reader.ReadFloat;
            Line.Color := Color;
            Line.LineWidth := LineWidth;
            Shapes.Add(Line);
          end
          else if ShapeType = 'Rectangle' then
          begin
            var Rect := TRectangle.Create;
            Rect.P1.X := Reader.ReadFloat;
            Rect.P1.Y := Reader.ReadFloat;
            Rect.P2.X := Reader.ReadFloat;
            Rect.P2.Y := Reader.ReadFloat;
            Rect.Color := Color;
            Rect.LineWidth := LineWidth;
            Shapes.Add(Rect);
          end
          else if ShapeType = 'Circle' then
          begin
            var Circle := TCircle.Create;
            Circle.Center.X := Reader.ReadFloat;
            Circle.Center.Y := Reader.ReadFloat;
            Circle.Radius := Reader.ReadFloat;
            Circle.Color := Color;
            Circle.LineWidth := LineWidth;
            Shapes.Add(Circle);
          end;
        end;
        Reader.ReadListEnd;
      finally
        Reader.Free;
      end;
    finally
      Stream.Free;
    end;
    PaintBox.Invalidate;
  end;
end;

procedure TForm5.btnLineClick(Sender: TObject);
begin
  CurrentTool := ttLine;
end;

procedure TForm5.btnRectangleClick(Sender: TObject);
begin
  CurrentTool := ttRectangle;
end;

procedure TForm5.btnCircleClick(Sender: TObject);
begin
  CurrentTool := ttCircle;
end;

procedure TForm5.btnSelectionClick(Sender: TObject);
begin
  CurrentTool := ttSelection;
end;

procedure TForm5.cmbLineWidthChange(Sender: TObject);
var
  Obj: TShape;
begin
  LineWidth := StrToIntDef(cmbLineWidth.Text, 1);
  for Obj in SelectedShapes do
    Obj.LineWidth := LineWidth;
  PaintBox.Invalidate;
end;

procedure TForm5.PaintBoxMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbRight then
  begin
    if CurrentTool = ttSelection then
    begin
      IsPanning := True;
      StartPanPoint := fCanvas.PixelToPoint(TPoint.Create(X, Y));
    end;
  end
  else
  begin
    StartPoint := fCanvas.PixelToPoint(TPoint.Create(X, Y));
    IsDrawing := True;

    if CurrentTool = ttSelection then
    begin
      IsSelecting := True;
      SelectObject(StartPoint.X, StartPoint.Y, ssCtrl in Shift);
    end;
  end;
end;

procedure TForm5.PaintBoxMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  p: T2DPoint;
begin
  p := fCanvas.PixelToPoint(TPoint.Create(X, Y));

  if IsPanning and (ssRight in Shift) and (CurrentTool = ttSelection) then
  begin
    var dx := -(p.X - StartPanPoint.X);
    var dy := -(p.Y - StartPanPoint.Y);
    fCanvas.SetBounds(fCanvas.xmin+dx, fCanvas.ymin+dy, fCanvas.xmax+dx, fCanvas.ymax+dy);
    PaintBox.Invalidate;
  end
  else if (CurrentTool = ttSelection) and IsSelecting and (SelectedShapes.Count > 0) then
  begin
    MoveSelectedObject(p.x - StartPoint.x, p.y - StartPoint.y);
    StartPoint := p;
    PaintBox.Invalidate;
  end
  else if IsDrawing then
  begin
    EndPoint := p;
    PaintBox.Invalidate;
  end;
end;

procedure TForm5.PaintBoxMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  Shape: TShape;
begin
  if Button = mbRight then
    IsPanning := False
  else
  begin
    IsDrawing := False;
    IsSelecting := False;

    if CurrentTool <> ttSelection then
    begin
      EndPoint := fCanvas.PixelToPoint(TPoint.Create(X, Y));

      case CurrentTool of
        ttLine:
          begin
            Shape := TLine.Create;
            TLine(Shape).P1 := StartPoint;
            TLine(Shape).P2 := EndPoint;
          end;
        ttRectangle:
          begin
            Shape := TRectangle.Create;
            TRectangle(Shape).P1 := StartPoint;
            TRectangle(Shape).P2 := EndPoint;
          end;
        ttCircle:
          begin
            Shape := TCircle.Create;
            TCircle(Shape).Center := StartPoint;
            TCircle(Shape).Radius := Sqrt(Sqr(EndPoint.X - StartPoint.X) + Sqr(EndPoint.Y - StartPoint.Y));
          end;
      else
        Shape := nil;
      end;

      if Assigned(Shape) then
      begin
        Shape.Color := SelectedColor;
        Shape.LineWidth := LineWidth;
        Shapes.Add(Shape);
      end;
    end
    else
    begin
      PaintBox.Invalidate;
    end;
  end;
end;

procedure TForm5.PaintBoxPaint(Sender: TObject);
var
  CanvasAdapter: TCanvasAdapter;
  Shape: TShape;
begin
  CanvasAdapter := fCanvas;
  try
    for Shape in Shapes do
    begin
      Shape.Draw(CanvasAdapter);
      if Shape.IsSelected then
      begin
        CanvasAdapter.SetCurrentColor(clRed);
        CanvasAdapter.SetCurrentLineWidth(2);
        CanvasAdapter.LockedStyle := true;
        Shape.Draw(CanvasAdapter);
        CanvasAdapter.LockedStyle := false;
      end;
    end;

    if IsDrawing then
      DrawTemporaryShape(CanvasAdapter);
  finally
  end;
end;

procedure TForm5.DrawTemporaryShape(CanvasAdapter: TCanvasAdapter);
var
  Shape: TShape;
begin
  case CurrentTool of
    ttLine:
      begin
        Shape := TLine.Create;
        TLine(Shape).P1 := StartPoint;
        TLine(Shape).P2 := EndPoint;
      end;
    ttRectangle:
      begin
        Shape := TRectangle.Create;
        TRectangle(Shape).P1 := StartPoint;
        TRectangle(Shape).P2 := EndPoint;
      end;
    ttCircle:
      begin
        Shape := TCircle.Create;
        TCircle(Shape).Center := StartPoint;
        TCircle(Shape).Radius := Sqrt(Sqr(EndPoint.X - StartPoint.X) + Sqr(EndPoint.Y - StartPoint.Y));
      end;
  else
    Shape := nil;
  end;

  if Assigned(Shape) then
  begin
    Shape.Color := SelectedColor;
    Shape.LineWidth := LineWidth;
    Shape.Draw(CanvasAdapter);
    Shape.Free;
  end;
end;

procedure TForm5.ColorBoxChange(Sender: TObject);
var
  Obj: TShape;
begin
  SelectedColor := ColorBox.Selected;
  for Obj in SelectedShapes do
    Obj.Color := SelectedColor;
  PaintBox.Invalidate;
end;

procedure TForm5.SelectObject(const x, y: Single; AddToSelection: Boolean);
var
  i: Integer;
  Obj: TShape;
  AlreadySelected: Boolean;
begin
  if not AddToSelection then
  begin
    for i := 0 to Shapes.Count - 1 do
      Shapes[i].IsSelected := False;
    SelectedShapes.Clear;
  end;

  var tol := 10 * fCanvas.ScaleFactor;
  for i := Shapes.Count - 1 downto 0 do
  begin
    Obj := Shapes[i];
    if Obj.IsPointInside(x, y, tol) then
    begin
      AlreadySelected := Obj.IsSelected;

      if AddToSelection then
      begin
        Obj.IsSelected := not Obj.IsSelected;
        if Obj.IsSelected then
          SelectedShapes.Add(Obj)
        else
          SelectedShapes.Remove(Obj);
      end
      else
      begin
        if not AlreadySelected then
        begin
          SelectedShapes.Clear;
          for var j := 0 to Shapes.Count - 1 do
            Shapes[j].IsSelected := False;
          Obj.IsSelected := True;
          SelectedShapes.Add(Obj);
        end;
      end;
      Break;
    end;
  end;
  PaintBox.Repaint;
end;

procedure TForm5.MoveSelectedObject(const dx, dy: Single);
var
  Obj: TShape;
begin
  for Obj in SelectedShapes do
    Obj.MoveTo(dx, dy);
  PaintBox.Invalidate;
end;

procedure TForm5.PaintBoxMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
begin
  var p := fCanvas.PixelToPoint(MousePos);
  var k := 1.2;
  if WheelDelta>0 then
    k := 1/k;
  fCanvas.xmin := p.x+k*(fcanvas.xmin-p.x);
  fCanvas.xmax := p.x+k*(fcanvas.xmax-p.x);
  fCanvas.ymin := p.y+k*(fcanvas.ymin-p.y);
  fCanvas.ymax := p.y+k*(fcanvas.ymax-p.y);
  PaintBox.Invalidate;
  Handled := True;
end;

procedure TForm5.FormMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
begin
  // Вызов обработчика колеса мыши для PaintBox
  PaintBoxMouseWheel(Sender, Shift, WheelDelta, PaintBox.ScreenToClient(MousePos), Handled);
end;

{ T2DPoint }

constructor T2DPoint.Create(const x, y: double);
begin
  self.x := x;
  self.y := y;
end;

function T2DPoint.Length: double;
begin
  result := sqrt(x*x+y*y);
end;

class operator T2DPoint.Multiply(const d: double; const p: T2DPoint): T2DPoint;
begin
  result.x := d*p.x;
  result.y := d*p.y;
end;

class operator T2DPoint.Subtract(const p1, p2: T2DPoint): T2DPoint;
begin
  result.x := p2.x-p1.x;
  result.y := p2.y-p1.y;
end;

end.
