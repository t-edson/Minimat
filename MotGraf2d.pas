{Define un objeto "Motor gráfico", que permite dibujar en un lienzo virtual,
de coordenadas de tipo Double, que luego se transformarán a coordenadas de la
pantalla (en pixeles).
El sisetma de coordenadas, sigue la dirección usual en geometría:

Y  /|\
    |
    |
    |
    |
    +--------------------> X
}
unit MotGraf2d;
{$mode objfpc}{$H+}
interface
uses
  Classes, SysUtils, Graphics, ExtCtrls, Controls;
type
  { TMotGraf }
  TMotGraf = class
    //Parámetros de la cámara (perspectiva)
    x_cam      : Single;  //coordenadas de la camara
    y_cam      : Single;
    Zoom       : Single;     //factor de ampliación
    {Desplazamiento para ubicar el centro virtual de la pantalla (0,0)
    Se indica en pixeles. Si por ejemplo, se fija:
    x_Des = 10 y y_Des = 10
    Hará que cuando se dibuje algo virtualmente en (0,0), aparecerá desplazado
    10 pixeles a la derecha del borde izquierdo y 10 pixeles arriba del borde inferior}
    x_des      : integer;
    y_des      : Integer;
{  public
    ImageList  : TImageList;
    constructor IniMotGraf(canvas0: Tcanvas);
    procedure FijaModoEscrit(modo:TFPPenMode);
    procedure FijaLapiz(estilo:TFPPenStyle; ancho:Integer; color:Tcolor);
    procedure FijaRelleno(ColorR:TColor);
    procedure FijaColor(colLin,colRel:TColor; ancho: Integer = 1); //Fija colorde línea y relleno

    procedure Linea(x1, y1, x2, y2:Single);
    procedure Linea0(x1, y1, x2, y2: Integer);
    procedure rectang(x1, y1, x2, y2: Single);
    procedure rectang0(x1, y1, x2, y2: Integer);
    procedure RectangR(x1, y1, x2, y2: Single);
    procedure RectangR0(x1, y1, x2, y2: Integer);
    procedure RectRedonR(x1, y1, x2, y2: Single);
    procedure Barra(x1, y1, x2, y2: Single; colFon: TColor=-1);
    procedure Barra0(x1, y1, x2, y2: Integer; colFon: TColor);
    procedure poligono(x1, y1, x2, y2, x3, y3: Single; x4: Single=-10000;
      y4: Single=-10000; x5: Single=-10000; y5: Single=-10000; x6: Single=-10000;
      y6: Single=-10000);
    procedure Polygon(const Points: array of TFPoint);
    //funciones para texto
    procedure SetFont(Letra: string);
    procedure SetText(color: TColor; tam: single);
    procedure SetText(negrita: Boolean=False; cursiva: Boolean=False;
      subrayado: Boolean=False);
    procedure SetText(color: TColor; tam: single; Letra: String;
      negrita: Boolean=False; cursiva: Boolean=False; subrayado: Boolean=False);
    procedure Texto(x1, y1: Single; txt: String);
    procedure TextRect(x1, y1, x2, y2: Single; x0, y0: Single; const Text: string;
      const Style: TTextStyle);
    procedure TextoR(x1, y1, ancho, alto: Single; txt: String);
    function TextWidth(const txt: string): single;  //ancho del texto

    procedure GuardarPerspectivaEn(var p: TPerspectiva);
    procedure LeePerspectivaDe(p: TPerspectiva);

    procedure FijarVentana(ScaleWidth, ScaleHeight: Real; xMin, xMax, yMin, yMax: Real);
    procedure Desplazar(dx, dy: Integer);
    procedure ObtenerDesplaz2(xr, yr: Integer; Xant, Yant: Integer; var dx,dy: Single);
    procedure DibujarIcono(x1, y1: Single; idx: integer);
    procedure DibujarImagen(im: TGraphic; x1, y1, dx, dy: Single);
    procedure DibujarImagenN(im: TGraphic; x1, y1: Single);
    procedure DibujarImagen0(im: TGraphic; x1, y1, dx, dy: Integer);

    procedure XYvirt(xp, yp: Integer; var xv, yv: Single);
    procedure XYpant(xv, yv: Single; var xp, yp: Integer);
    function Xvirt(xr, yr: Integer): Single;  //INLINE Para acelerar las llamadas
    function Yvirt(xr, yr: Integer): Single;  //INLINE Para acelerar las llamadas
    function XPant(x: Single): Integer;    //INLINE Para acelerar las llamadas
    function YPant(y: Single): Integer;    //INLINE Para acelerar las llamadas
    //funciones básicas para dibujo de Controles
    procedure DibBorBoton(x1,y1:Single; ancho,alto: Single);
    procedure DibFonBotonOsc(x1, y1: Single; ancho, alto: Single);
    procedure DibCheck(px, py: Single; ancho, alto: Single);
    procedure DibVnormal(x1, y1: Single; ancho, alto: Single);
    procedure DrawTrianUp(x1,y1:Single; ancho,alto: Single);
    procedure DrawTrianDown(x1,y1:Single; ancho,alto: Single);
}
  private
    gControl: TGraphicControl;   //Control gráfico, en donde se va a dibujar
    cv      : Tcanvas;           //referencia al lienzo
    function GetPenColor: TColor;
    procedure SetPenColor(AValue: TColor);
    function XPant(x: Single): Integer; inline;
    function YPant(y: Single): Integer; inline;
  public
    property PenColor: TColor read GetPenColor write SetPenColor;
    procedure Clear;
    procedure Line(const x1,y1,x2,y2: Double);
  public  //Inicialización
    constructor Create(gContrl0: TGraphicControl);
    destructor Destroy; override;
  end;

implementation

{ TMotGraf }
procedure TMotGraf.Clear;
begin
  gControl.Canvas.Brush.Color := clBlack;
  gControl.Canvas.FillRect(0,0,gControl.Width,gControl.Height);
end;
function TMotGraf.XPant(x:Single): Integer; inline;   //INLINE Para acelerar las llamadas
//Función de la geometría del motor. Da la transformación lineal de la coordenada x.
begin
//   XPant := Round((x - x_cam) * Zoom + x_des);
  Result := Round(x+x_des);
end;
function TMotGraf.YPant(y:Single): Integer; inline;  //INLINE Para acelerar las llamadas
//Función de la geometría del motor. Da la transformación lineal de la coordenada y.
begin
//   YPant := Round((y - y_cam) * Zoom + y_des);
  Result := Round(gControl.Height-(y+y_des));
end;
procedure TMotGraf.SetPenColor(AValue: TColor);
begin
  cv.Pen.Color:=AValue;
end;
function TMotGraf.GetPenColor: TColor;
begin
  Result := cv.Pen.Color;
end;
procedure TMotGraf.Line(const x1, y1, x2, y2: Double);
begin
  cv.Line(XPant(x1), YPant(y1), XPant(x2), YPant(y2));
end;
constructor TMotGraf.Create(gContrl0: TGraphicControl);
begin
  gControl := gContrl0;
  cv := gControl.Canvas;
  x_des := 10;
  y_des := 10;
end;
destructor TMotGraf.Destroy;
begin
  inherited Destroy;
end;

end.

