{Implementación de un interprete sencillo para el lenguaje Xpres.
Este módulo no generará código sino que lo ejecutará directamente.
Este intérprete, solo reconoce tipos de datos enteros y de cadena.
Para los enteros se implementan las operaciones aritméticas básicas, y
para las cadenas se implementa solo la concatenación(+)
Se pueden crear nuevas variables.

En este archivo, se pueden declarar tipos, variables, constantes,
procedimientos y funciones. Hay rutinas obligatorias que siempre se deben
implementar.

Este intérprete, está implementado con una arquitectura de pila.

* Todas las operaciones recibe sus dos parámetros en las variables p1 y p2.
* El resultado de cualquier expresión se debe dejar indicado en el objeto "res".
* Los valores enteros y enteros sin signo se cargan en valInt
* Los valores string se cargan en valStr
* Las variables están mapeadas en el arreglo vars[]
* Cada variable, de cualquier tipo, ocupa una celda de vars[]
* Los parámetros de las funciones se pasan siempre usando la pila.

Los procedimientos de operaciones, deben actualizar en el acumulador:

* El tipo de resultado (para poder evaluar la expresión completa como si fuera un
operando nuevo)
* La categoría del operador (constante, expresión, etc), para poder optimizar la generación
de código.

Ceerado Por Tito Hinostroza  30/07/2014
Modificado Por Tito Hinostroza  8/08/2015
Modificado Por Tito Hinostroza  29/11/2016
}
unit GenCod;
{$mode objfpc}{$H+}
interface
uses
  Classes, SysUtils, Graphics, SynEditHighlighter, MisUtils, SynFacilBasic,
  XpresParser, XpresTypes, XpresElements;
const
  STACK_SIZE = 32;
type

  { TGenCod }

  TGenCod = class(TCompilerBase)
  private
    procedure bol_asig_bol;
    procedure bol_procLoad;
    procedure flt_asig_flt;
    procedure flt_divi_flt;
    procedure flt_igual_flt;
    procedure flt_mult_flt;
    procedure flt_procLoad;
    procedure flt_resta_flt;
    procedure flt_suma_flt;
    procedure fun_close(fun: TxpEleFun);
    procedure fun_fileopen(fun: TxpEleFun);
    procedure fun_messagebox(fun: TxpEleFun);
    procedure fun_messageboxI(fun: TxpEleFun);
    procedure fun_puts(fun: TxpEleFun);
    procedure fun_putsI(fun: TxpEleFun);
    procedure fun_write(fun: TxpEleFun);
    procedure LoadResBol(val: Boolean; catOp: TCatOperan);
    procedure LoadResFloat(const val: Double; const catOp: TCatOperan);
    procedure LoadResInt(val: int64; catOp: TCatOperan);
    procedure LoadResStr(val: string; catOp: TCatOperan);
    procedure _menos_flt;
    procedure PopResult;
    procedure PushResult;
    procedure str_asig_str;
    procedure str_concat_str;
    procedure str_igual_str;
    procedure str_procLoad;
  protected   //Tipos adicionales de tokens
    tnStruct   : integer;
    tnExpDelim : integer;
    tnBlkDelim : integer;
    tnOthers   : integer;
    procedure Cod_StartData;
    procedure Cod_StartProgram;
    procedure Cod_EndProgram;
    procedure expr_start;
    procedure expr_end(isParam: boolean);
  public
    /////// Tipos de datos del lenguaje ////////////
    tipInt : TType;   //Entero
    tipFlt : TType;   //Coma flotante
    tipStr : Ttype;   //Cadena
    tipBol : TType;   //Booleano
    //Pila virtual
    {La pila virtual se representa con una tabla. Cada vez que se agrega un valor con
    pushResult, se incrementa "sp". Para retornar "sp" a su valor original, se debe llamar
    a PopResult(). Luego de eso, se accede a la pila, de acuerdo al seguienet esquema:
    Cuando se usa cpara almacenar los parámetros de las funciones, queda así:
    stack[sp]   -> primer parámetro
    stack[sp+1] -> segundo parámetro
    ...
    }
    sp: integer;  //puntero de pila
    stack: array[0..STACK_SIZE-1] of TOperand;
    procedure DefineSyntax;
    procedure DefineOperations;
  end;


implementation

procedure TGenCod.LoadResInt(val: int64; catOp: TCatOperan);
//Carga en el resultado un valor entero
begin
    res.typ := tipInt;
    res.valInt:=val;
    res.catOp:=catOp;
end;
procedure TGenCod.LoadResFloat(const val: Double; const catOp: TCatOperan);
//Carga en el resultado un valor entero
begin
    res.typ := tipFlt;
    res.valFloat:=val;
    res.catOp:=catOp;
end;
procedure TGenCod.LoadResStr(val: string; catOp: TCatOperan);
//Carga en el resultado un valor string
begin
    res.typ := tipStr;
    res.valStr:=val;
    res.catOp:=catOp;
end;
procedure TGenCod.LoadResBol(val: Boolean; catOp: TCatOperan);
//Carga en el resultado un valor string
begin
    res.typ := tipBol;
    res.valBool:=val;
    res.catOp:=catOp;
end;
procedure TGenCod.PushResult;
//Coloca el resultado de una expresión en la pila
begin
  if sp>=STACK_SIZE then begin
    GenError('Desborde de pila.');
    exit;
  end;
  stack[sp].typ := res.typ;
  case res.Typ.cat of
  t_string:  stack[sp].valStr  := res.ReadStr;
  t_integer: stack[sp].valInt  := res.ReadInt;
  end;
  Inc(sp);
end;
procedure TGenCod.PopResult;
//Reduce el puntero de pila, de modo que queda apuntando al último dato agregado
begin
  if sp<=0 then begin
    GenError('Desborde de pila.');
    exit;
  end;
  Dec(sp);
end;
////////////rutinas obligatorias
procedure TGenCod.Cod_StartData;
//Codifica la parte inicial de declaración de variables estáticas
begin
end;
procedure TGenCod.Cod_StartProgram;
//Codifica la parte inicial del programa
begin
  sp := 0;  //inicia pila
  //////// variables predefinidas ////////////
//  CreateVariable('timeout', 'int');
  CreateVariable('curIP', 'string');
  CreateVariable('curTYPE', 'string');
  CreateVariable('curPORT', 'int');
  CreateVariable('curENDLINE', 'string');
  CreateVariable('curAPP', 'string');
  CreateVariable('promptDETECT', 'boolean');
  CreateVariable('promptSTART', 'string');
  CreateVariable('promptEND', 'string');
end;
procedure TGenCod.Cod_EndProgram;
//Codifica la parte inicial del programa
begin
end;
procedure TGenCod.expr_start;
//Se ejecuta siempre al StartSyntax el procesamiento de una expresión
begin
  if exprLevel=1 then begin //es el primer nivel
    res.typ := tipInt;   //le pone un tipo por defecto
  end;
end;
procedure TGenCod.expr_end(isParam: boolean);
//Se ejecuta al final de una expresión, si es que no ha habido error.
begin
  if isParam then begin
    //Se terminó de evaluar un parámetro
    PushResult;   //pone parámetro en pila
    if HayError then exit;
  end;
end;
//////////// Operaciones con flotantes ////////////////
procedure TGenCod.flt_procLoad;
begin
  //carga el operando en res
  LoadResFloat(p1^.ReadFloat, p1^.catOp);
end;
procedure TGenCod._menos_flt;
begin
  //carga el operando en res
  LoadResFloat(-p1^.ReadFloat, p1^.catOp);
end;
procedure TGenCod.flt_asig_flt;
begin
  if p1^.catOp <> coVariab then begin  //validación
    GenError('Solo se puede asignar a variable.'); exit;
  end;
  //en la VM se puede mover directamente res memoria sin usar el registro res
  p1^.rVar.valFloat := p2^.ReadFloat;
  //Toas las expresiones deben devolver valor
  LoadResFloat(p1^.rVar.valFloat, coExpres);
end;
procedure TGenCod.flt_suma_flt;
begin
  LoadResFloat(p1^.ReadFloat+p2^.ReadFloat, coExpres);
end;
procedure TGenCod.flt_resta_flt;
begin
  LoadResFloat(p1^.ReadFloat-p2^.ReadFloat, coExpres);
end;
procedure TGenCod.flt_mult_flt;
begin
  LoadResFloat(p1^.ReadFloat*p2^.ReadFloat, coExpres);
end;
procedure TGenCod.flt_divi_flt;
begin
  LoadResFloat(p1^.ReadFloat/p2^.ReadFloat, coExpres);
end;
procedure TGenCod.flt_igual_flt;
begin
  LoadResBol(p1^.ReadFloat = p2^.ReadFloat, coExpres);
end;

////////////operaciones con string
procedure TGenCod.str_procLoad;
begin
  //carga el operando en res
  res.typ := tipStr;
  res.valStr := p1^.ReadStr;
end;
procedure TGenCod.str_asig_str;
begin
  if p1^.catOp <> coVariab then begin  //validación
    GenError('Solo se puede asignar a variable.'); exit;
  end;
  //aquí se puede mover directamente res memoria sin usar el registro res
  p1^.rVar.valStr := p2^.ReadStr;
  //  res.used:=false;  //No hay obligación de que la asignación devuelva un valor.
{  if Upcase(p1^.rVar.name) = 'CURIP' then begin
    //variable interna
    config.fcConex.IP := p2^.ReadStr;
    config.fcConex.UpdateChanges;  //actualiza
  end else if Upcase(p1^.rVar.name) = 'CURTYPE' then begin
    //variable interna
    case UpCase(p2^.ReadStr) of
    'TELNET': config.fcConex.tipo := TCON_TELNET;  //Conexión telnet común
    'SSH'   : config.fcConex.tipo := TCON_SSH;     //Conexión ssh
    'SERIAL': config.fcConex.tipo := TCON_SERIAL;  //Serial
    'OTHER' : config.fcConex.tipo := TCON_OTHER;   //Otro proceso
    end;
    config.fcConex.UpdateChanges;  //actualiza
  end;}
end;

procedure TGenCod.str_concat_str;
begin
  LoadResStr(p1^.ReadStr + p2^.ReadStr, coExpres);
end;
procedure TGenCod.str_igual_str;
begin
  LoadResBol(p1^.ReadStr = p2^.ReadStr, coExpres);
end;
////////////operaciones con boolean
procedure TGenCod.bol_procLoad;
begin
  //carga el operando en res
  res.typ := tipStr;
  res.valBool := p1^.ReadBool;
end;
procedure TGenCod.bol_asig_bol;
begin
  if p1^.catOp <> coVariab then begin  //validación
    GenError('Solo se puede asignar a variable.'); exit;
  end;
  //en la VM se puede mover directamente res memoria sin usar el registro res
  p1^.rVar.valBool := p2^.ReadBool;
//  res.used:=false;  //No hay obligación de que la asignación devuelva un valor.
{  if Upcase(p1^.rVar.name) = 'PROMPTDETECT' then begin
    //variable interna
    config.fcDetPrompt.detecPrompt := p2^.ReadBool;
    config.fcDetPrompt.ConfigCambios;  //actualiza
  end;}
end;

//funciones básicas
procedure TGenCod.fun_puts(fun :TxpEleFun);
//envia un texto a consola
begin
  PopResult;  //saca parámetro 1
  if HayError then exit;
  msgbox(stack[sp].valStr);  //sabemos que debe ser String
  //el tipo devuelto lo fijará el framework, al tipo definido
end;
procedure TGenCod.fun_putsI(fun :TxpEleFun);
//envia un texto a consola
begin
  PopResult;  //saca parámetro 1
  if HayError then exit;
  msgbox(IntToStr(stack[sp].valInt));  //sabemos que debe ser Entero
  //el tipo devuelto lo fijará el framework, al tipo definido
end;
procedure TGenCod.fun_messagebox(fun :TxpEleFun);
begin
  PopResult;  //saca parámetro 1
  if HayError then exit;
  msgbox(stack[sp].valStr);  //sabemos que debe ser String
  //el tipo devuelto lo fijará el framework, al tipo definido
end;
procedure TGenCod.fun_messageboxI(fun :TxpEleFun);
begin
  PopResult;  //saca parámetro 1
  if HayError then exit;
  msgbox(IntToStr(stack[sp].valInt));  //sabemos que debe ser String
  //el tipo devuelto lo fijará el framework, al tipo definido
end;
procedure TGenCod.fun_fileopen(fun: TxpEleFun);
var
  nom: String;
  modo: Int64;
  n: THandle;
begin
  PopResult;
  PopResult;
  PopResult;
//  AssignFile(filHand, stack[sp].valStr);
//  Rewrite(filHand);
  nom := stack[sp+1].valStr;
  modo := stack[sp+2].valInt;
  if modo = 0 then begin
    if not FileExists(nom) then begin
      //Si no existe. lo crea
      n := FileCreate(nom);
      FileClose(n);
    end;
    n := FileOpen(nom, fmOpenReadWrite);
    stack[sp].valInt:= Int64(n);
  end else begin
    n := FileOpen(nom, fmOpenRead);
    stack[sp].valInt:=Int64(n);
  end;
end;
procedure TGenCod.fun_close(fun: TxpEleFun);
begin
  PopResult;  //manejador de archivo
  fileclose(stack[sp].valInt);
end;
procedure TGenCod.fun_write(fun: TxpEleFun);
var
  cad: String;
begin
  PopResult;  //manejador de archivo
  PopResult;  //cadena
  cad := stack[sp+1].valStr;
  filewrite(stack[sp].valInt, cad , length(cad));
end;
procedure TGenCod.DefineSyntax;
//Se ejecuta solo una vez al inicio
var
  p: tFaTokContent;
begin
  OnExprStart := @expr_start;
  OnExprEnd := @expr_End;
  ///////////// Crea tipos de tokens personalizados /////////
  tnExpDelim := xLex.NewTokType('ExpDelim');//delimitador de expresión ";"
  tnBlkDelim := xLex.NewTokType('BlkDelim'); //delimitador de bloque
  tnStruct   := xLex.NewTokType('Struct');   //personalizado
  tnOthers   := xLex.NewTokType('Others');   //personalizado
  //Configura apariencia
  tkKeyword.Style := [fsBold];     //en negrita
  xLex.Attrib[tnBlkDelim].Foreground:=clGreen;
  xLex.Attrib[tnBlkDelim].Style := [fsBold];    //en negrita
  xLex.Attrib[tnStruct].Foreground:=clGreen;
  xLex.Attrib[tnStruct].Style := [fsBold];      //en negrita
  ///////////////// Configura la sintaxis /////////////////////
  xLex.ClearMethodTables;           //limpìa tabla de métodos
  xLex.ClearSpecials;               //para empezar a definir tokens
  //crea tokens por contenido
  xLex.DefTokIdentif('[$A-Za-z_]', '[A-Za-z0-9_]*');
  //Definición completa de números en coma flotante
  //xLex.DefTokContent('[0-9]', '[0-9.]*', tkNumber);
  p := xLex.DefTokContent('[0-9]', tnNumber);
  p.AddInstruct('[0-9]*');
  p.AddInstruct('[\.]','','move(+2)');
  p.AddInstruct('[0-9]+','','exit(-1)');
  p.AddInstruct('[eE]');
  p.AddInstruct('[+-]?');
  p.AddInstruct('[0-9]+','','exit(-2)');
  //Define palabras claves.
  {Notar que si se modifica aquí, se debería también, actualizar el archivo XML de
  sintaxis, para que el resaltado y completado sea consistente.}
  xLex.AddIdentSpecList('ENDIF ELSE ELSEIF', tnBlkDelim);
  xLex.AddIdentSpecList('true false', tnBoolean);
  xLex.AddIdentSpecList('CLEAR CONNECT CONNECTSSH DISCONNECT SENDLN WAIT PAUSE STOP', tnSysFunct);
  xLex.AddIdentSpecList('LOGOPEN LOGWRITE LOGCLOSE LOGPAUSE LOGSTART', tnSysFunct);
  xLex.AddIdentSpecList('FILEOPEN FILECLOSE FILEWRITE', tnSysFunct);
  xLex.AddIdentSpecList('MESSAGEBOX CAPTURE ENDCAPTURE EDIT DETECT_PROMPT', tnSysFunct);
  xLex.AddIdentSpecList('IF', tnStruct);
  xLex.AddIdentSpecList('THEN', tnKeyword);
  //símbolos especiales
  xLex.AddSymbSpec(';',  tnExpDelim);
  xLex.AddSymbSpec(',',  tnExpDelim);
  xLex.AddSymbSpec('+',  tnOperator);
  xLex.AddSymbSpec('-',  tnOperator);
  xLex.AddSymbSpec('*',  tnOperator);
  xLex.AddSymbSpec('/',  tnOperator);
  xLex.AddSymbSpec('^',  tnOperator);
  xLex.AddSymbSpec('=',  tnOperator);
  xLex.AddSymbSpec('==', tnOperator);
  xLex.AddSymbSpec('(',  tnOthers);
  xLex.AddSymbSpec(')',  tnOthers);
  xLex.AddSymbSpec(':',  tnOthers);
  //crea tokens delimitados
  xLex.DefTokDelim('''','''', tnString);
  xLex.DefTokDelim('"','"', tnString);
  xLex.DefTokDelim('//','', xLex.tnComment);
  xLex.DefTokDelim('/\*','\*/', xLex.tnComment, tdMulLin);
  //define bloques de sintaxis
  xLex.AddBlock('[',']');
  xLex.Rebuild;   //es necesario para terminar la definición
end;
procedure TGenCod.DefineOperations;
var
  opr: TxpOperator;
  f: TxpEleFun;
begin
  ///////////Crea tipos y operaciones
  ClearTypes;
  tipInt := CreateType('int'   , t_integer, 8);
  tipFlt := CreateType('float' , t_float, 8);   //de 8 bytes
  tipStr := CreateType('string', t_string,-1);   //de longitud variable
  tipBol := CreateType('boolean',t_boolean,1);

  //////// Operaciones con Float////////////
  tipFlt.OperationLoad:=@flt_procLoad;
  opr := tipFlt.CreateUnaryPreOperator('-', 6, 'signo', @_menos_flt);
  opr := tipFlt.CreateBinaryOperator('=', 1, 'asig');
  opr.CreateOperation(tipFlt,@flt_asig_flt);
  opr := tipFlt.CreateBinaryOperator('+', 3, 'suma');
  opr.CreateOperation(tipFlt,@flt_suma_flt);
  opr := tipFlt.CreateBinaryOperator('-', 3, 'resta');
  opr.CreateOperation(tipFlt,@flt_resta_flt);
  opr := tipFlt.CreateBinaryOperator('*', 4, 'mult');
  opr.CreateOperation(tipFlt,@flt_mult_flt);
  opr := tipFlt.CreateBinaryOperator('/', 4, 'divi');
  opr.CreateOperation(tipFlt,@flt_divi_flt);
  opr := tipFlt.CreateBinaryOperator('^', 4, 'divi');
  opr.CreateOperation(tipFlt,@flt_divi_flt);
  opr := tipFlt.CreateBinaryOperator('==', 2, 'igual');
  opr.CreateOperation(tipFlt,@flt_igual_flt);

  //////// Operaciones con String ////////////
  tipStr.OperationLoad:=@str_procLoad;

  opr:=tipStr.CreateBinaryOperator('=',1,'asig');  //asignación
  opr.CreateOperation(tipStr,@str_asig_str);
  opr:=tipStr.CreateBinaryOperator('+',3,'concat');
  opr.CreateOperation(tipStr,@str_concat_str);
  opr:=tipStr.CreateBinaryOperator('==',2,'igual');
  opr.CreateOperation(tipStr,@str_igual_str);

  //////// Operaciones con Boolean ////////////
  tipBol.OperationLoad:=@bol_procLoad;
  opr:=tipBol.CreateBinaryOperator('=',1,'asig');  //asignación
  opr.CreateOperation(tipBol,@bol_asig_bol);

  //////// Funciones básicas ////////////
  f := CreateSysFunction('puts', tipInt, @fun_puts);
  f.CreateParam('',tipStr);
  f := CreateSysFunction('puts', tipInt, @fun_putsI);  //sobrecargada
  f.CreateParam('',tipInt);
  f := CreateSysFunction('messagebox', tipInt, @fun_messagebox);
  f.CreateParam('',tipStr);
  f := CreateSysFunction('messagebox', tipInt, @fun_messageboxI);
  f.CreateParam('',tipInt);
  f := CreateSysFunction('fileopen', tipInt, @fun_fileopen);
  f.CreateParam('',tipInt);
  f.CreateParam('',tipStr);
  f.CreateParam('',tipInt);
  f := CreateSysFunction('fileclose', tipInt, @fun_close);
  f.CreateParam('',tipInt);
  f := CreateSysFunction('filewrite', tipInt, @fun_write);
  f.CreateParam('',tipInt);
  f.CreateParam('',tipStr);
  if FindDuplicFunction then exit;
end;

end.

