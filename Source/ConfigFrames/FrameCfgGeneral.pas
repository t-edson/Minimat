unit FrameCfgGeneral;
{$mode objfpc}{$H+}
interface
uses
  Classes, SysUtils, FileUtil, Forms, Controls, StdCtrls, MiConfigBasic;

type

  { TfraCfgGeneral }
  TfraCfgGeneral = class(TFrame)
    chkVerInspVar: TCheckBox;
  public
    VerInspVar: boolean;
    procedure Iniciar(cfgFile: TMiConfigBasic); //Inicia el frame
    procedure SetLanguage(lang: string);
  end;

implementation
{$R *.lfm}

{ TfraCfgGeneral }
procedure TfraCfgGeneral.Iniciar(cfgFile: TMiConfigBasic);
begin
  cfgFile.Asoc_Bol(self.Name + '/VerInspVar', @VerInspVar , chkVerInspVar,  true);
end;

procedure TfraCfgGeneral.SetLanguage(lang: string);
begin

end;

end.

