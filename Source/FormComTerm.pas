unit FormComTerm;
{$mode objfpc}{$H+}
interface
uses
  Classes, SysUtils, FileUtil, SynEdit, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, Grids, StdCtrls, ComCtrls, LCLType,
  SynEditMarkupHighAll, SynEditKeyCmds, MisUtils, SynFacilUtils, FormGraf3D,
  uResaltTerm, FormConfig, EvalExpres, Parser, Globales, GenCod;

type

  { TfrmComTerm }

  TfrmComTerm = class(TForm)
    edCom : TSynEdit;
    Label1: TLabel;
    Panel1: TPanel;
    Splitter1: TSplitter;
    StatusBar1: TStatusBar;
    StringGrid1: TStringGrid;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure Panel1Click(Sender: TObject);
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

  public
    cxp : TCompiler;
    ejecMac: boolean;   //indica que se esta´ejecuatando un "script"
  end;

var
  frmComTerm: TfrmComTerm;

implementation

{$R *.lfm}

{ TfrmComTerm }

procedure TfrmComTerm.Panel1Click(Sender: TObject);
begin

end;

procedure TfrmComTerm.InicTerminal;
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
procedure TfrmComTerm.InsertText(txt: string);
{Inserta un texto en el panel de comandos, agregando previamente un salto de línea}
begin
  //Se prefiere usar comandos antes que manipular directamente lines[], para no
  //"desorientar" al SynEdit.
  edCom.ExecuteCommand(ecInsertLine, ' ', nil);
  edCom.ExecuteCommand(ecDown, ' ', nil);
  edCom.InsertTextAtCaret(txt);
end;
procedure TfrmComTerm.InsertPrompt;
{Agrega el prompt en la pantalla, después de haber escrito algo en pantalla.}
begin
  InsertText(Config.fcPanCom.Prompt);
end;
procedure TfrmComTerm.FormCreate(Sender: TObject);
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
procedure TfrmComTerm.FormShow(Sender: TObject);
begin
  InicTerminal;   //configura después de iniciar "Config"
end;
procedure TfrmComTerm.FormDestroy(Sender: TObject);
begin
  cxp.Destroy;
  eval.Destroy;
  eCom.Free;
  hlTerm.Free;
end;
procedure TfrmComTerm.EjecutarComando(txt: string);
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
    if cxp.res.typ = cxp.tipInt then begin
      InsertText(IntToStr(cxp.res.valInt));
    end else if cxp.res.typ = cxp.tipFlt then begin
      InsertText(FloatToStr(cxp.res.valFloat));
    end else begin
      InsertText('Tipo desconocido.');
    end;
  end;
end;
procedure TfrmComTerm.eCom_KeyDown(Sender: TObject; var Key: Word;
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
procedure TfrmComTerm.eComKeyUp(Sender: TObject; var Key: Word;
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
procedure TfrmComTerm.eComKeyPress(Sender: TObject; var Key: char);
begin
  if edCom.CaretY = edCom.Lines.Count then begin
    //Es última línea, deja pasar todo
  end else begin   //Es otra línea
    Key := #0;   //no permite la edición, en estas líneas
  end;
end;


end.

