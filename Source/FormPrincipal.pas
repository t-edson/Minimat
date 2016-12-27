unit FormPrincipal;
{$mode objfpc}{$H+}
interface

uses
  Classes, SysUtils, FileUtil, SynEdit, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, ActnList, Menus, StdCtrls, Grids, ComCtrls, LCLType, LCLProc,
  SynEditMarkupHighAll,
  SynFacilUtils, MisUtils, FormGraf3D, uResaltTerm, FormConfig, EvalExpres;
const
  NUM_CUAD = 20;
  ZOOM_INI = 12;

type

  { TfrmPrincipal }
  TfrmPrincipal = class(TForm)
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
    Panel1: TPanel;
    Splitter1: TSplitter;
    StatusBar1: TStatusBar;
    StringGrid1: TStringGrid;
    edCom: TSynEdit;
    VerGraf2D: TAction;
    VerGraf3D: TAction;
    procedure edTermKeyPress(Sender: TObject; var Key: char);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure HerConfigExecute(Sender: TObject);
    procedure VerGraf3DExecute(Sender: TObject);
  private
    eCom: TSynFacilEditor;
    hlTerm    : TResaltTerm;
    eval      : TEvalExpres;   //evaluador de expresiones
    procedure eComKeyPress(Sender: TObject; var Key: char);
    procedure eComKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure eCom_KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure InicTerminal;
    procedure InsertPrompt;
    function InvalidCursor(x, y: integer; var prmLon: integer): boolean;
  public

  end;

var
  frmPrincipal: TfrmPrincipal;

implementation
{$R *.lfm}
procedure TfrmPrincipal.InicTerminal;
var
  SynMarkup: TSynEditMarkupHighlightAllCaret;  //para resaltar palabras iguales
begin
  edCom.Highlighter := hlTerm;  //asigna resaltador

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
procedure TfrmPrincipal.InsertPrompt;
{Agrgea el prompt en la pantalla, después de haber escrito algo en pantalla.}
begin
  edCom.Lines.Add(Config.fcPanCom.Prompt);
  edCom.CaretY:=edCom.Lines.Count;  //posiciona cursor
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
procedure TfrmPrincipal.eCom_KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  cad: String;
  res: Texpre;
  prmLon: Integer;
begin
  if Key = VK_RETURN then begin
    if edCom.CaretY = edCom.Lines.Count then begin
      //Porcesar comando
      cad := edCom.LineText;
      delete(cad,1, length(Config.fcPanCom.Prompt));
      res := eval.EvaluarLinea(cad);
      edCom.Lines.Add(res.valTxt);  //escribe respuesta
      //Agrega prompt
      InsertPrompt;
      Key := 0;   //para que no agregue otra línea
    end;
  end else if Key in [VK_LEFT, VK_HOME] then begin
    //Estas teclas podrían mover el cursor al área del prompt
    if InvalidCursor(edCom.CaretX-1, edCom.CaretY, prmLon) then begin
      edCom.CaretX:=prmLon+1;
      Key := 0;   //cancela el movimiento
    end;
  end else if Key in [VK_DOWN] then begin
    if InvalidCursor(edCom.CaretX, edCom.CaretY+1, prmLon) then begin
      edCom.CaretY := edCom.CaretY + 1;
      edCom.CaretX:=prmLon+1;
      Key := 0;   //cancela el movimiento
    end;
  end else if Key in [VK_UP] then begin
    if InvalidCursor(edCom.CaretX, edCom.CaretY-1, prmLon) then begin
      edCom.CaretY := edCom.CaretY - 1;
      edCom.CaretX:=prmLon+1;
      Key := 0;   //cancela el movimiento
    end;
{  end else if (Key in [VK_A..VK_Z, VK_0..VK_9,
                       VK_ADD, VK_SUBTRACT, VK_MULTIPLY, VK_DIVIDE,
                       VK_SEPARATOR, VK_DECIMAL])  then begin
    //Caracteres imprimibles
    if Config.ContienePrompt(edCom.LineText)=0 then begin
      //No está en la línea del prompt
      Key := 0;   //no permite la edición, en estas líneas
    end;}
  end;
end;
procedure TfrmPrincipal.eComKeyPress(Sender: TObject; var Key: char);
begin
  if Config.ContienePrompt(edCom.LineText)>0 then begin
    //Es línea del prompt
{    if Key in ['a'..'z','A'..'Z','0'..'9','+','-','*','/','.',' '])  then begin
      //Deja pasar
    end else begin
    end;}
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
  eCom.OnKeyPress:=@eComKeyPress;
  eval := TEvalExpres.Create;  //Crea su evaluador de expresiones
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
procedure TfrmPrincipal.FormDestroy(Sender: TObject);
begin
  eval.Destroy;
  eCom.Free;
  hlTerm.Free;
end;
///////////////////////////// Acciones ///////////////////////////////
procedure TfrmPrincipal.VerGraf3DExecute(Sender: TObject);
begin
  frmGraf3D.Show;
end;
procedure TfrmPrincipal.eComKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin

end;

procedure TfrmPrincipal.edTermKeyPress(Sender: TObject; var Key: char);
begin

end;

procedure TfrmPrincipal.FormClose(Sender: TObject; var CloseAction: TCloseAction
  );
begin
  Config.escribirArchivoIni();
end;

procedure TfrmPrincipal.HerConfigExecute(Sender: TObject);
begin
  Config.Configurar();
end;

end.

