unit FormPrincipal;
{$mode objfpc}{$H+}
interface

uses
  Classes, SysUtils, FileUtil, SynEdit, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, ActnList, Menus, StdCtrls, Grids, ComCtrls, LCLType,
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
    edTerm: TSynEdit;
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
    eTerm: TSynFacilEditor;
    hlTerm    : TResaltTerm;
    eval      : TEvalExpres;   //evaluador de expresiones
    procedure eTermKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure InicTerminal;
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
  edTerm.Highlighter := hlTerm;  //asigna resaltador

  //Inicia resaltado de palabras iguales
  SynMarkup := TSynEditMarkupHighlightAllCaret(edTerm.MarkupByClass[TSynEditMarkupHighlightAllCaret]);
  SynMarkup.MarkupInfo.FrameColor := clSilver;
  SynMarkup.MarkupInfo.Background := clBlack;
  SynMarkup.MarkupInfo.StoredName:='ResPalAct';  //para poder identificarlo

  SynMarkup.WaitTime := 250; // millisec
  SynMarkup.Trim := True;     // no spaces, if using selection
  SynMarkup.FullWord := True; // only full words If "Foo" is under caret, do not mark it in "FooBar"
  SynMarkup.IgnoreKeywords := False;

  //  edTerm.Font.Name:='Courier New';
 //  edTerm.Font.Size:=10;
 //resalta
  edTerm.Options:=[eoBracketHighlight];
  //Limita posición X del cursor para que no escape de la línea
  edTerm.Options := edTerm.Options + [eoKeepCaretX];
  //permite indentar con <Tab>
  edTerm.Options := edTerm.Options + [eoTabIndent];
  //trata a las tabulaciones como un caracter
  edTerm.Options2 := edTerm.Options2 + [eoCaretSkipTab];
//  edTerm.OnSpecialLineMarkup:=@edTermSpecialLineMarkup;  //solo para corregir falla de resaltado de línea actual
end;

procedure TfrmPrincipal.eTermKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  cad: String;
  res: Texpre;
begin
  if Key = VK_RETURN then begin
    if edTerm.CaretY = edTerm.Lines.Count then begin
      //Porcesar comando
      cad := edTerm.LineText;
      delete(cad,1, length(Config.fcPanCom.Prompt));
      res := eval.EvaluarLinea(cad);
      edTerm.Lines.Add(res.valTxt);  //escribe respuesta
      //Agrega prompt
      edTerm.Lines.Add(Config.fcPanCom.Prompt);
      edTerm.CaretY:=edTerm.Lines.Count;  //posiciona cursor
      Key := 0;   //para que no agregue otra línea
    end;
  end;
end;

procedure TfrmPrincipal.FormCreate(Sender: TObject);
begin
  hlTerm := TResaltTerm.Create(Self);  //crea resaltador
  eTerm := TSynFacilEditor.Create(edTerm,'SinNombre','sh');   //Crea Editor
  eTerm.PanCursorPos := StatusBar1.Panels[2];  //panel para la posición del cursor
  eTerm.OnKeyDown:=@eTermKeyDown;
  eval := TEvalExpres.Create;  //Crea su evaluador de expresiones
end;
procedure TfrmPrincipal.FormShow(Sender: TObject);
begin
  Config.SetLanguage('en');
  //aquí ya sabemos que Config está creado. Lo configuramos
  Config.edTerm := edTerm;  //pasa referencia de editor.

  Config.Iniciar(nil);  //Inicia la configuración
  InicTerminal;   //configura después de iniciar "Config"
VerGraf3DExecute(self);
frmGraf3D.btnGraficClick(self);
frmGraf3D.SetFocus;
end;
procedure TfrmPrincipal.FormDestroy(Sender: TObject);
begin
  eval.Destroy;
  eTerm.Free;
  hlTerm.Free;
end;

///////////////////////////// Acciones ///////////////////////////////
procedure TfrmPrincipal.VerGraf3DExecute(Sender: TObject);
begin
  frmGraf3D.Show;
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

