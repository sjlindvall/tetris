unit Tetris;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Objects, FMX.Ani, FMX.Layouts, FMX.Controls.Presentation, FMX.StdCtrls;

type
  TRotation = (R0,R90,R180,R270);

  TShape = (I,O,T,S,Z,J,L);

  TFormTetrisGame = class(TForm)
    ButtonDrop: TButton;
    ButtonRoter: TButton;
    ButtonLeft: TButton;
    ButtonRight: TButton;
    procedure FormCreate(Sender: TObject);
    procedure ButtonDropClick(Sender: TObject);
    procedure ButtonRoterClick(Sender: TObject);
    procedure AnimationDone(Sender: TObject);
    procedure RotationDone(Sender: TObject);
    procedure DropNextStep(Sender: TObject);
    procedure ButtonLeftClick(Sender: TObject);
    procedure ButtonRightClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);

  private
    { Private declarations }
    procedure CreateIshape(thisShape : TFMXObject; rotation:TRotation);
    procedure CreateOshape(thisShape: TFMXObject);
    procedure CreateTshape(thisShape : TFMXObject; rotation:TRotation);
    procedure CreateSshape(thisShape : TFMXObject; rotation:TRotation);
    procedure CreateZshape(thisShape : TFMXObject; rotation:TRotation);
    procedure CreateJshape(centerX,centerY:Single; rotation:TRotation);
    procedure CreateLshape(centerX,centerY:Single; rotation:TRotation);
    function CreateShape(tetriMino:TShape; centerX,centerY:Single; rotation:TRotation): TLayout;
    function CreateBlock(AParent: TFmxObject; GridX, GridY: Integer; AColor: TAlphaColor): TRectangle;
    procedure SetupRotation;
    procedure DoRotation;
    function NextRotation(R: TRotation): TRotation;

  public
    { Public declarations }
  end;

const
  BLOCK_SIZE = 30;
  LIMIT_LEFT = BLOCK_SIZE;
  LIMIT_RIGHT = BLOCK_SIZE*10;
  LIMIT_BOTTOM = BLOCK_SIZE*20;

var
  FormTetrisGame: TFormTetrisGame;
  Rect: TRectangle;
  theShape: TLayout;
  Animation, Rotation: TFloatAnimation;
  CurrentRotation: TRotation = R0;
  DropTimer: TTimer;


implementation

{$R *.fmx}

function TFormTetrisGame.NextRotation(R: TRotation): TRotation;
begin
  case R of
    R0:    Result := R90;
    R90:   Result := R180;
    R180:  Result := R270;
    R270:  Result := R0;
  end;
end;

procedure TFormTetrisGame.FormCreate(Sender: TObject);
begin
  Self.OnKeyDown := FormKeyDown;

  // Lag timer
  DropTimer := TTimer.Create(Self);
  DropTimer.Interval := 500;           // 500 ms = én drop per halvt sekund
  DropTimer.OnTimer := DropNextStep;
  DropTimer.Enabled := True;

  // Lag rektangelet
  Rect := TRectangle.Create(Self);
  Rect.Parent := Self;
  Rect.Width := 30;
  Rect.Height := 30;
  Rect.Position.X := 10;
  Rect.Position.Y := 40;

  Rect.Fill.Color := TAlphaColorRec.Skyblue;     // Lysere blå gir mer liv
  Rect.Stroke.Color := TAlphaColorRec.Navy;      // Mørk blå gir kontrast
  Rect.Stroke.Thickness := 1;                    // Tykkelse på rammen

  Rect.Fill.Kind := TBrushKind.Gradient;
  Rect.Fill.Gradient.Color := TAlphaColorRec.Skyblue;
  Rect.Fill.Gradient.Color1 := TAlphaColorRec.Lightcyan;
  Rect.Fill.Gradient.StartPosition.X := 0;
  Rect.Fill.Gradient.StartPosition.Y := 0;

  Rect.Fill.Gradient.StopPosition.X := 1;
  Rect.Fill.Gradient.StopPosition.Y := 1;

  theShape := CreateShape(TShape.Z, 60,10, TRotation.R0);
  theShape.RotationCenter.X := 0.5;
  theShape.RotationCenter.Y := 0.5;

  // Opprett animasjonen
  Animation := TFloatAnimation.Create(theShape);
  Animation.Parent := theShape;
  Animation.OnFinish := AnimationDone;
  Animation.PropertyName := 'Position.Y';
  Animation.StartValue := 10;
  Animation.StopValue := 300;
  Animation.Duration := 2.0;
  Animation.Loop := False;
  Animation.Enabled := False;

  SetupRotation;

end;

procedure TFormTetrisGame.DropNextStep(Sender: TObject);
begin
  theShape.Position.Y := theShape.Position.Y + BLOCK_SIZE;
end;

procedure TFormTetrisGame.FormKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
begin
  case Key of
    vkLeft:  ButtonLeftClick(Sender); {theShape.Position.X := theShape.Position.X - BLOCK_SIZE;}
    vkRight: ButtonRightClick(Sender); {theShape.Position.X := theShape.Position.X + BLOCK_SIZE;}
    vkUp:    DoRotation;
    vkDown:  theShape.Position.Y := theShape.Position.Y + BLOCK_SIZE;
  end;
end;

procedure TFormTetrisGame.ButtonDropClick(Sender: TObject);
begin
  Animation.Enabled := True;
end;

procedure TFormTetrisGame.ButtonLeftClick(Sender: TObject);
begin
  if theShape.Position.X > LIMIT_LEFT then
  begin
    theShape.Position.X := theShape.Position.X - BLOCK_SIZE;
  end;
end;

procedure TFormTetrisGame.ButtonRightClick(Sender: TObject);
begin
  if theShape.Position.X < LIMIT_RIGHT then
  begin
    theShape.Position.X := theShape.Position.X + BLOCK_SIZE;
  end;
end;

procedure TFormTetrisGame.ButtonRoterClick(Sender: TObject);
begin
  DoRotation;
end;

procedure TFormTetrisGame.AnimationDone(Sender: TObject);
begin
  ShowMessage('droppet!');
end;

procedure TFormTetrisGame.SetupRotation;
begin
    // Roter
  Rotation := TFloatAnimation.Create(theShape);
  Rotation.Parent := theShape;
  Rotation.OnFinish := RotationDone;
  Rotation.PropertyName := 'RotationAngle';
  Rotation.StartValue := 0;
  Rotation.StopValue := 90;
  Rotation.Duration := 0.25;
  Rotation.Loop := False;
  Rotation.Enabled := False;
end;

procedure TFormTetrisGame.DoRotation;
begin
  DropTimer.Enabled := False; // Pause drop mens vi roterer

  CurrentRotation := NextRotation(CurrentRotation);
  Rotation.Enabled := False;
  Rotation.StartValue := theShape.RotationAngle;
  Rotation.StopValue := Rotation.StartValue + 90;
  Rotation.Enabled := True;
end;

procedure TFormTetrisGame.RotationDone(Sender: TObject);
begin
  DropTimer.Enabled := True; // Resume drop etter rotasjon
end;

function TFormTetrisGame.CreateBlock(AParent: TFmxObject; GridX, GridY: Integer; AColor: TAlphaColor): TRectangle;
begin
  Result := TRectangle.Create(AParent);
  Result.Parent := AParent;
  Result.Width := BLOCK_SIZE;
  Result.Height := BLOCK_SIZE;
  Result.Position.X := GridX * BLOCK_SIZE;
  Result.Position.Y := GridY * BLOCK_SIZE;
  Result.Fill.Color := AColor;
  Result.Stroke.Kind := TBrushKind.Solid;
  Result.Stroke.Color := TAlphaColorRec.Black;
  Result.Stroke.Thickness := 1;
end;

procedure TFormTetrisGame.CreateIshape(thisShape: TFMXObject; rotation: TRotation);
begin
  CreateBlock(thisShape, 0, 1, TAlphaColorRec.Blue);
  CreateBlock(thisShape, 1, 1, TAlphaColorRec.Blue);
  CreateBlock(thisShape, 2, 1, TAlphaColorRec.Blue);
  CreateBlock(thisShape, 3, 1, TAlphaColorRec.Blue);
end;

procedure TFormTetrisGame.CreateOshape(thisShape: TFMXObject);
begin
  CreateBlock(thisShape, 0, 1, TAlphaColorRec.Gray);
  CreateBlock(thisShape, 1, 1, TAlphaColorRec.Gray);
  CreateBlock(thisShape, 0, 0, TAlphaColorRec.Gray);
  CreateBlock(thisShape, 1, 0, TAlphaColorRec.Gray);
end;

procedure TFormTetrisGame.CreateTshape(thisShape : TFMXObject; rotation:TRotation);
begin
  CreateBlock(thisShape, 0, 1, TAlphaColorRec.Green);
  CreateBlock(thisShape, 1, 1, TAlphaColorRec.Green);
  CreateBlock(thisShape, 2, 1, TAlphaColorRec.Green);
  CreateBlock(thisShape, 1, 0, TAlphaColorRec.Green);
end;

procedure TFormTetrisGame.CreateSshape(thisShape : TFMXObject; rotation:TRotation);
begin
  CreateBlock(thisShape, 0, 1, TAlphaColorRec.Red);
  CreateBlock(thisShape, 1, 1, TAlphaColorRec.Red);
  CreateBlock(thisShape, 1, 0, TAlphaColorRec.Red);
  CreateBlock(thisShape, 2, 0, TAlphaColorRec.Red);
end;

procedure TFormTetrisGame.CreateZshape(thisShape : TFMXObject; rotation:TRotation);
begin
  CreateBlock(thisShape, 0, 0, TAlphaColorRec.Purple);
  CreateBlock(thisShape, 1, 0, TAlphaColorRec.Purple);
  CreateBlock(thisShape, 1, 1, TAlphaColorRec.Purple);
  CreateBlock(thisShape, 2, 1, TAlphaColorRec.Purple);
end;

procedure TFormTetrisGame.CreateLshape(centerX,centerY:Single; rotation:TRotation);
begin
  CreateBlock(Self, 100, 200, TAlphaColorRec.Orange);
  CreateBlock(Self, 130, 200, TAlphaColorRec.Orange);
  CreateBlock(Self, 160, 200, TAlphaColorRec.Orange);
  CreateBlock(Self, 160, 170, TAlphaColorRec.Orange);
end;

procedure TFormTetrisGame.CreateJshape(centerX,centerY:Single; rotation:TRotation);
begin
  CreateBlock(Self, 200, 200, TAlphaColorRec.Yellow);
  CreateBlock(Self, 230, 200, TAlphaColorRec.Yellow);
  CreateBlock(Self, 260, 200, TAlphaColorRec.Yellow);
  CreateBlock(Self, 200, 170, TAlphaColorRec.Yellow);
end;


function TFormTetrisGame.CreateShape(tetriMino:TShape; centerX,centerY:Single; rotation:TRotation): TLayout;
var
  tetrisShape : TLayout;
begin
  tetrisShape := TLayout.Create(Self);
  tetrisShape.Parent := Self;

  case tetriMino of
    I:
      begin
        tetrisShape.Width := BLOCK_SIZE * 4;
        tetrisShape.Height := BLOCK_SIZE * 4;
        tetrisShape.Position.X := centerX - (tetrisShape.Width / 2);
        tetrisShape.Position.Y := centerY - (tetrisShape.Height / 2);
        CreateIshape(tetrisShape, rotation);
      end;
    O:
      begin
        tetrisShape.Width := BLOCK_SIZE * 2;
        tetrisShape.Height := BLOCK_SIZE * 2;
        tetrisShape.Position.X := centerX - (tetrisShape.Width / 2);
        tetrisShape.Position.Y := centerY - (tetrisShape.Height / 2);
        CreateOshape(tetrisShape);
      end;
    T:
      begin
        tetrisShape.Width := BLOCK_SIZE * 3;
        tetrisShape.Height := BLOCK_SIZE * 2;
        tetrisShape.Position.X := centerX - (tetrisShape.Width / 2);
        tetrisShape.Position.Y := centerY - (tetrisShape.Height / 2);
        CreateTshape(tetrisShape, rotation);
      end;
    S:
      begin
        tetrisShape.Width := BLOCK_SIZE * 3;
        tetrisShape.Height := BLOCK_SIZE * 2;
        tetrisShape.Position.X := centerX - (tetrisShape.Width / 2);
        tetrisShape.Position.Y := centerY - (tetrisShape.Height / 2);
        CreateSshape(tetrisShape, rotation);
      end;

    Z:
      begin
        tetrisShape.Width := BLOCK_SIZE * 3;
        tetrisShape.Height := BLOCK_SIZE * 2;
        tetrisShape.Position.X := centerX - (tetrisShape.Width / 2);
        tetrisShape.Position.Y := centerY - (tetrisShape.Height / 2);
        CreateZshape(tetrisShape, rotation);
      end;

    J: ;
    L: ;
  end;



  Result := tetrisShape;
end;

end.
