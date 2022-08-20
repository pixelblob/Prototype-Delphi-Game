program Project1;

{$R *.dres}

uses
  Forms,
  Unit3 in 'Unit3.pas' {Form3},
  gameObjectManagement in 'gameObjectManagement.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm3, Form3);
  Application.Run;
end.
