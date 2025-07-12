program TetrisGame;

uses
  System.StartUpCopy,
  FMX.Forms,
  Tetris in 'Tetris.pas' {FormTetrisGame};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TFormTetrisGame, FormTetrisGame);
  Application.Run;
end.
