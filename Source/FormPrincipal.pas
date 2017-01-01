unit FormPrincipal;
{$mode objfpc}{$H+}
interface

uses
  Classes, SysUtils, FileUtil, SynEdit, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, ActnList, Menus, StdCtrls, Grids, ComCtrls, LCLType, LCLProc,
  SynEditMarkupHighAll, SynEditKeyCmds, MisUtils, SynFacilUtils, FormGraf3D,
  uResaltTerm, FormConfig, EvalExpres, Parser, Globales, GenCod;
const
  NUM_CUAD = 20;
  ZOOM_INI = 12;

type

  { TfrmPrincipal }
  TfrmPrincipal = class(TForm)
    acAyuAcerca: TAction;
    HerConfig: TAction;
    ActionList1: TActionList;
    ArcAbrir: TAction;
    Label1: TLabel;
    MainMenu1: TMainMenu;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    MenuItem6: TMenuItem;
    MenuItem7: TMenuItem;
    MenuItem8: TMenuItem;
    MenuItem9: TMenuItem;
    Panel1: TPanel;
    Splitter1: TSplitter;
    StatusBar1: TStatusBar;
    StringGrid1: TStringGrid;
    edCom: TSynEdit;
    VerGraf2D: TAction;
    VerGraf3D: TAction;
    procedure acAyuAcercaExecute(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure HerConfigExecute(Sender: TObject);
    procedure VerGraf3DExecute(Sender: TObject);
  private
    eCom      : TSynFacilEditor;
    hlTerm    : TResaltTerm;
    eval      : TEvalExpres;   //evaluador de expresiones
    procedure eComKeyPress(Sender: TObject; var Key: char);
    procedure eComKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure eCom_KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure EjecutarComando(txt: string);
    procedure InicTerminal;
    procedure InsertPrompt;
    procedure InsertText(txt: string);
    function InvalidCursor(x, y: integer; var prmLon: integer): boolean;
  public
    cxp : TCompiler;
    ejecMac: boolean;   //indica que se esta´ejecuatando un "script"
    procedure ActualizarInfoPanel0;
  end;

var
  frmPrincipal: TfrmPrincipal;

implementation
{$R *.lfm}
procedure TfrmPrincipal.InicTerminal;
var
  SynMarkup: TSynEditMarkupHighlightAllCaret;  //para resaltar palabras iguales
begin
//  edCom.Highlighter := hlTerm;  //asigna resaltador
  edCom.Highlighter := cxp.xLex;

  //Inicia resaltado de palabras iguales
  SynMarkup := TSynEditMarkupHighlightAllCaret(edCom.MarkupByClass[TSynEditMarkupHighlightAllCaret]);
  SynMarkup.MarkupInfo.FrameColor := clSilver;
  SynMarkup.MarkupInfo.Background := clBlack;
  SynMarkup.MarkupInfo.StoredName:='ResPalAct';  //para poder identificarlo

  SynMarkup.WaitTime := 250; // millisec
  SynMarkup.Trim := True;     // no spaces, if using selection
  SynMarkup.FullWord := True; // only full words If "Foo" is under caret, do not mark it in "FooBar"
  SynMarkup.IgnoreKeywords := False;

  //  edCom.Font.Name:='Courier New';
 //  edCom.Font.Size:=10;
 //resalta
  edCom.Options:=[eoBracketHighlight];
  //Limita posición X del cursor para que no escape de la línea
  edCom.Options := edCom.Options + [eoKeepCaretX];
  //permite indentar con <Tab>
  edCom.Options := edCom.Options + [eoTabIndent];
  //trata a las tabulaciones como un caracter
  edCom.Options2 := edCom.Options2 + [eoCaretSkipTab];
//  edCom.OnSpecialLineMarkup:=@edTermSpecialLineMarkup;  //solo para corregir falla de resaltado de línea actual
  InsertPrompt;
end;
procedure TfrmPrincipal.InsertText(txt: string);
{Inserta un texto en el panel de comandos, agregando previamente un salto de línea}
begin
  //Se prefiere usar comandos antes que manipular directamente lines[], para no
  //"desorientar" al SynEdit.
  edCom.ExecuteCommand(ecInsertLine, ' ', nil);
  edCom.ExecuteCommand(ecDown, ' ', nil);
  edCom.InsertTextAtCaret(txt);
end;
procedure TfrmPrincipal.InsertPrompt;
{Agrega el prompt en la pantalla, después de haber escrito algo en pantalla.}
begin
  InsertText(Config.fcPanCom.Prompt);
end;
function TfrmPrincipal.InvalidCursor(x, y: integer; var prmLon: integer): boolean;
{Velida si la posición indicada del cursor, cae en una posición prohibida, es decir,
encima del cursor.
Devuelve la longitud del prompt en "prmLon"}
var
  lin: String;
begin
  if y <1 then exit(false);
  if y > edCom.Lines.Count then exit(false);
  lin := edCom.Lines[y-1];
  prmLon := Config.ContienePrompt(lin);
  if (prmLon>0) and (X <= prmLon) then begin
    exit(true);
  end else begin
    exit(false);
  end;
end;
procedure TfrmPrincipal.ActualizarInfoPanel0;
//Actualiza el panel 0, con información de la conexión o de la ejecución de macros
begin
   StatusBar1.Panels[0].Text:='Listo.';
   //refresca para asegurarse, porque el panel 0 está en modo gráfico
   StatusBar1.InvalidatePanel(0,[ppText]);
end;
procedure TfrmPrincipal.EjecutarComando(txt: string);
var
  long: Integer;
begin
  long := length(Config.fcPanCom.Prompt);
  cxp.ExecuteStr(txt);
  if cxp.HayError then begin  //Hubo error
    //Pone marca sobre la posición del error
    InsertText(space(long + cxp.PErr.nColError-1) + '^');
    InsertText('ERROR: ' + cxp.PErr.TxtError);
  end else begin  //Sin error
    if cxp.res.typ = tipInt then begin
      InsertText(IntToStr(cxp.res.valInt));
    end else if cxp.res.typ = tipFlt then begin
      InsertText(FloatToStr(cxp.res.valFloat));
    end else begin
      InsertText('Tipo desconocido.');
    end;
  end;
end;
procedure TfrmPrincipal.eCom_KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  cad: String;
begin
  if Key = VK_RETURN then begin
    if edCom.CaretY = edCom.Lines.Count then begin
      //Porcesar comando
      cad := edCom.LineText;
      delete(cad,1, length(Config.fcPanCom.Prompt));
      EjecutarComando(cad);
      //Agrega prompt
      InsertPrompt;
      Key := 0;   //para que no agregue otra línea
      edCom.ClearUndo;   //para que no permita deshacer comandos anteriores
    end else begin
      //Está en una línea anterior
      Key := 0;
    end;
  end else if edCom.CaretY = edCom.Lines.Count then begin
    //En la última línea (en el prompt)
    if (shift = []) and (Key in [VK_LEFT, VK_HOME]) then begin
      //Estas teclas podrían mover el cursor al área del prompt
      edCom.CaretX:=length(Config.fcPanCom.Prompt)+1;
      Key := 0;   //cancela el movimiento
    end;
  end;
end;
procedure TfrmPrincipal.eComKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  prmLon: integer;
begin
  prmLon := length(Config.fcPanCom.Prompt);
  if (prmLon>0) and (edCom.CaretX <= prmLon) and (edCom.CaretY = edCom.Lines.Count) then begin
    //posición prohibida
    edCom.CaretX:=prmLon+1;
  end;
end;
procedure TfrmPrincipal.eComKeyPress(Sender: TObject; var Key: char);
begin
  if edCom.CaretY = edCom.Lines.Count then begin
    //Es última línea, deja pasar todo
  end else begin   //Es otra línea
    Key := #0;   //no permite la edición, en estas líneas
  end;
end;
procedure TfrmPrincipal.FormCreate(Sender: TObject);
begin
  hlTerm := TResaltTerm.Create(Self);  //crea resaltador
  eCom := TSynFacilEditor.Create(edCom,'SinNombre','sh');   //Crea Editor
  eCom.PanCursorPos := StatusBar1.Panels[2];  //panel para la posición del cursor
  eCom.OnKeyDown:=@eCom_KeyDown;
  eCom.OnKeyUp:=@eComKeyUp;
  eCom.OnKeyPress:=@eComKeyPress;
  eval := TEvalExpres.Create;  //Crea su evaluador de expresiones
  cxp := TCompiler.Create;
end;
procedure TfrmPrincipal.FormShow(Sender: TObject);
begin
  Config.SetLanguage('en');
  //aquí ya sabemos que Config está creado. Lo configuramos
  Config.edTerm := edCom;  //pasa referencia de editor.

  Config.Iniciar(nil);  //Inicia la configuración
  InicTerminal;   //configura después de iniciar "Config"
VerGraf3DExecute(self);
frmGraf3D.btnGraficClick(self);
frmGraf3D.SetFocus;
end;
procedure TfrmPrincipal.FormClose(Sender: TObject; var CloseAction: TCloseAction
  );
begin
  Config.escribirArchivoIni();
end;
procedure TfrmPrincipal.FormDestroy(Sender: TObject);
begin
  cxp.Destroy;
  eval.Destroy;
  eCom.Free;
  hlTerm.Free;
end;
///////////////////////////// Acciones ///////////////////////////////
procedure TfrmPrincipal.VerGraf3DExecute(Sender: TObject);
begin
  frmGraf3D.Show;
end;
procedure TfrmPrincipal.HerConfigExecute(Sender: TObject);
begin
  Config.Configurar();
end;
procedure TfrmPrincipal.acAyuAcercaExecute(Sender: TObject);
begin
  msgbox(NOM_PROG + ' - ' + VER_PROG);
end;
end.

