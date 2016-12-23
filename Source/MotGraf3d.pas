unit MotGraf3d;
{$mode objfpc}{$H+}
interface

uses
  Classes, SysUtils, Graphics, ExtCtrls, Controls;
type
  Tpunto = record
    x : Single;
    y : Single;
    z : Single;
  end;

  { TMotGraf }
  TMotGraf = class
    //Parámetros de la cámara (perspectiva)
    x_cam   : Single;  //coordenadas de la camara
    y_cam   : Single;

    mAlfa : Single;     //ángulo "alfa"
    mFi   : Single;     //ánfulo "fi"
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
    //Funciones de transformación
    function XPant(xv, yv, zv: Single): Integer; inline;
    function YPant(xv, yv, zv: Single): Integer; inline;
    procedure XYpant(xv, yv, zv: Single; var xp, yp: Integer);
    function Xvirt(xr, yr: Integer): Single; inline;
    function Yvirt(xr, yr: Integer): Single; inline;
    procedure XYvirt(xp, yp: Integer; zv: Integer; var xv, yv: Single);
  public
    property PenColor: TColor read GetPenColor write SetPenColor;
    procedure Clear;
    procedure Line(const x1, y1, z1, x2, y2, z2: Double);
    procedure rectangXY3(x1, y1: Single; x2, y2: Single; z: Single);
    procedure poligono3(x1, y1, z1: Single; x2, y2, z2: Single; x3, y3,
      z3: Single; x4: Single=-10000; y4: Single=-10000; z4: Single=-10000;
      x5: Single=-10000; y5: Single=-10000; z5: Single=-10000; x6: Single=-
      10000; y6: Single=-10000; z6: Single=-10000);
    procedure polilinea3(x1, y1, z1: Single; x2, y2, z2: Single; x3, y3,
      z3: Single; x4: Single=-10000; y4: Single=-10000; z4: Single=-10000;
      x5: Single=-10000; y5: Single=-10000; z5: Single=-10000; x6: Single=-
      10000; y6: Single=-10000; z6: Single=-10000);
  public  //Inicialización
    constructor Create(gContrl0: TGraphicControl);
    destructor Destroy; override;
  end;

implementation

procedure TMotGraf.Clear;
begin
  gControl.Canvas.Brush.Color := clBlack;
  gControl.Canvas.FillRect(0,0,gControl.Width,gControl.Height);
end;
//*****************************FUNCIONES DE TRANSFORMACIÓN********************************
//Las siguientes funciones son por así decirlo, "estandar".
//Cuando se creen otras clases de dispositivo interfase gráfica deberían tener también estas
//funciones que son siempre necesarias.
function TMotGraf.Xvirt(xr, yr: Integer): Single;
//Obtiene la coordenada X virtual (del punto X,Y,Z ) a partir de unas coordenadas de
//pantalla.
var
  x2c, y2c: Single;
begin
  x2c := (xr - x_des) / Zoom;
  y2c := (yr - y_des) / Zoom;
  //caso z= 0, con inclinación. Equivalente a seleccionar en el plano XY
  Xvirt := (x2c * Cos(mAlfa) * Cos(mFi) + Sin(mAlfa) * y2c) / Cos(mFi) + x_cam;
end;
function TMotGraf.Yvirt(xr, yr: Integer): Single;
//Obtiene la coordenada Y virtual (del punto X,Y,Z ) a partir de unas coordenadas de
//pantalla.
var
  x2c, y2c: Single;
begin
  x2c := (xr - x_des) / Zoom;
  y2c := (yr - y_des) / Zoom;
  //caso z= 0, con inclinación. Equivalente a seleccionar en el plano XY
  Yvirt := (Cos(mAlfa) * y2c - x2c * Sin(mAlfa) * Cos(mFi)) / Cos(mFi) + y_cam;
end;
procedure TMotGraf.XYvirt(xp, yp: Integer; zv: Integer; var xv, yv: Single);
//Devuelve las coordenadas virtuales xv,yv a partir de unas coordenadas de pantalla
//(o del ratón). Debe indicarse el valor de Z. Equivale a intersecar un plano
//paralelo al plano XY con la línea de mira del ratón en pantalla.
var
  x2c, y2c : Single;
begin
  x2c := (xp - x_des) / Zoom;
  y2c := (yp - y_des) / Zoom;
  //Para ser legales, debería haber protección para cos(fi) = 0
  if zv = 0 then begin  //fórmula simplificada
      xv := (x2c * Cos(mAlfa) * Cos(mFi) + Sin(mAlfa) * y2c) / Cos(mFi) + x_cam;
      yv := (Cos(mAlfa) * y2c - x2c * Sin(mAlfa) * Cos(mFi)) / Cos(mFi) + y_cam;
  end else begin //para cualquier plano paralelo a XY
      xv := (x2c * Cos(mAlfa) * Cos(mFi) + Sin(mAlfa) * (y2c - zv * Sin(mFi))) / Cos(mFi) + x_cam;
      yv := (Cos(mAlfa) * (y2c - zv * Sin(mFi)) - x2c * Sin(mAlfa) * Cos(mFi)) / Cos(mFi) + y_cam;
  end;
  //Si los ángulos de vista alfa y fi son cero (caso normal), bastaría con
  //xv = x2c + x_cam
  //yv = y2c + y_cam
end;
function TMotGraf.XPant(xv, yv, zv: Single): Integer;   //INLINE Para acelerar las llamadas
//Función de la geometría del motor. Da la transformación lineal de la coordenada x.
//Obtiene el punto X en la pantalla donde realmente aparece un punto X,Y,Z
var
  x2c: ValReal;
begin
//   XPant := Round((xv - x_cam) * Zoom + x_des);
//  Result := Round(
//              (xv) * zoom + x_des
//            );
  x2c := (xv - x_cam) * Cos(mAlfa) - (yv - y_cam) * Sin(mAlfa);
  Xpant := Round(x_des + x2c * Zoom);
end;
function TMotGraf.YPant(xv, yv, zv: Single): Integer;  //INLINE Para acelerar las llamadas
//Función de la geometría del motor. Da la transformación lineal de la coordenada y.
//Obtiene el punto Y en la pantalla donde realmente aparece un punto X,Y,Z
var
  y2c: ValReal;
begin
//   YPant := Round((yv - y_cam) * Zoom + y_des);
//  Result := Round(gControl.Height-(
//              (yv) * zoom + y_des
//            ));
  y2c := ((yv - y_cam) * Cos(mAlfa) + (xv - x_cam) * Sin(mAlfa)) * Cos(mFi) + zv * Sin(mFi);
  Ypant := Round(y_des + y2c * Zoom);
end;
procedure TMotGraf.XYpant(xv, yv, zv: Single; var xp, yp: Integer);
begin
  xp := XPant(xv, yv, zv);
  yp := YPant(xv, yv, zv);
end;

procedure TMotGraf.SetPenColor(AValue: TColor);
begin
  cv.Pen.Color:=AValue;
end;
function TMotGraf.GetPenColor: TColor;
begin
  Result := cv.Pen.Color;
end;
//Funciones de dibujo
procedure TMotGraf.Line(const x1, y1, z1, x2, y2, z2: Double);
begin
//  cv.Line(XPant(x1+0.7*y1), YPant(z1+0.7*y1-0.5*x1),
//          XPant(x2+0.7*y2), YPant(z2+0.7*y2-0.5*x2));
  cv.Line(XPant(x1, y1, z1), YPant(x1, y1, z1),
          XPant(x2, y2, z2), YPant(x2, y2, z2));
end;
procedure TMotGraf.rectangXY3(x1, y1: Single; x2, y2: Single; z: Single);
//Dibuja un rectángulo, paralelo al plano XY
begin
 polilinea3(x1, y1, z, x2, y1, z, x2, y2, z, x1, y2, z);
End;
procedure TMotGraf.poligono3(x1,y1,z1: Single;
                  x2,y2,z2: Single;
                  x3,y3,z3: Single;
                  x4: Single = -10000; y4: Single = -10000; z4: Single = -10000;
                  x5: Single = -10000; y5: Single = -10000; z5: Single = -10000;
                  x6: Single = -10000; y6: Single = -10000; z6: Single = -10000);
//Dibuja un polígono relleno en 3D..
var
  Ptos3: array[1..7] of Tpunto;     //puntos 3d
  ptos: array[1..7] of TPoint;    //arreglo de puntos a dibujar
  nptos : integer;
  x1c, y1c : integer;
  i : integer;
begin
 Ptos3[1].x := x1; Ptos3[1].y := y1; Ptos3[1].z := z1;
 Ptos3[2].x := x2; Ptos3[2].y := y2; Ptos3[2].z := z2;
 Ptos3[3].x := x3; Ptos3[3].y := y3; Ptos3[3].z := z3;
 nptos := 3;
 If x4 <> -10000 Then begin Ptos3[4].x := x4; Ptos3[4].y := y4; Ptos3[4].z := z4; nptos := 4; end;
 If x5 <> -10000 Then begin Ptos3[5].x := x5; Ptos3[5].y := y5; Ptos3[5].z := z5; nptos := 5; end;
 If x6 <> -10000 Then begin Ptos3[6].x := x6; Ptos3[6].y := y6; Ptos3[6].z := z6; nptos := 6; end;
 //transformación 3d
 For i := 1 To nptos  do begin
     x1c := XPant(Ptos3[i].x, Ptos3[i].y, Ptos3[i].z);
     y1c := YPant(Ptos3[i].x, Ptos3[i].y, Ptos3[i].z);
     ptos[i].x := x1c;
     ptos[i].y := y1c;
 end;
 cv.Polygon(@ptos[1], nptos);   //dibuja borde
end;

procedure TMotGraf.polilinea3(x1, y1, z1: Single; x2, y2, z2: Single; x3, y3,
  z3: Single; x4: Single; y4: Single; z4: Single; x5: Single; y5: Single;
  z5: Single; x6: Single; y6: Single; z6: Single);
//Dibuja un polígono sin rellenar en 3D..
var
  Ptos3: array[1..7] of Tpunto;     //puntos 3d
  ptos: array[1..7] of TPoint;    //arreglo de puntos a dibujar
  nptos : integer;
  x1c, y1c : integer;
  i : integer;
begin
 Ptos3[1].x := x1; Ptos3[1].y := y1; Ptos3[1].z := z1;
 Ptos3[2].x := x2; Ptos3[2].y := y2; Ptos3[2].z := z2;
 Ptos3[3].x := x3; Ptos3[3].y := y3; Ptos3[3].z := z3;
 nptos := 3;
 If x4 <> -10000 Then begin Ptos3[4].x := x4; Ptos3[4].y := y4; Ptos3[4].z := z4; nptos := 4; end;
 If x5 <> -10000 Then begin Ptos3[5].x := x5; Ptos3[5].y := y5; Ptos3[5].z := z5; nptos := 5; end;
 If x6 <> -10000 Then begin Ptos3[6].x := x6; Ptos3[6].y := y6; Ptos3[6].z := z6; nptos := 6; end;
 //transformación 3d
 For i := 1 To nptos  do begin
     x1c := XPant(Ptos3[i].x, Ptos3[i].y, Ptos3[i].z);
     y1c := YPant(Ptos3[i].x, Ptos3[i].y, Ptos3[i].z);
     ptos[i].x := x1c;
     ptos[i].y := y1c;
 end;
 cv.Polyline(@ptos[1], nptos);   //dibuja borde
end;


constructor TMotGraf.Create(gContrl0: TGraphicControl);
begin
  gControl := gContrl0;
  cv := gControl.Canvas;
  x_des := 10;
  y_des := 10;
  zoom := 1;
end;
destructor TMotGraf.Destroy;
begin
  inherited Destroy;
end;

end.

