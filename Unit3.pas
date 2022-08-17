unit Unit3;

interface

uses
  Windows,
  Messages,
  SysUtils,
  Variants,
  Classes,
  Graphics,
  Controls,
  Forms,
  Dialogs,
  pngimage,
  ExtCtrls,
  jpeg,
  Math,
  Sockets,
  superobject,
  DateUtils, StdCtrls;

type
  TGameObject = class(TObject)
    x, y: Integer;
  end;

type

  TForm3 = class(TForm)
    Image1: TImage;
    gameLoop: TTimer;
    LevelImage: TImage;
    FpsReset: TTimer;
    screenBlankTimer: TTimer;
    warning: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure gameLoopTimer(Sender: TObject);
    procedure FpsResetTimer(Sender: TObject);
    procedure screenBlankTimerTimer(Sender: TObject);
    procedure Image1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form3: TForm3;
  jpg: TJPEGImage;
  forwardKey, backwardKey, leftKey, rightKey: Boolean;
  grassTileImages: array [1 .. 6] of TJPEGImage;
  bush, tree1, tree2, tree3, tree4, playerImage, selectorImage, nopeSelectorImage,
    heartImage: TGraphic;
  PlayerX, PlayerActualX, PlayerY, PlayerActualY, oldWindowX, oldWindowY,
    CURRENTFPS, FPS, cursorGridX, cursorGridY, playerQuadX,
    playerQuadY: Integer;
  Seed: Integer = 69420;
  Distance: Real;
  gameObjects: array of TGameObject;

const
  grassTileNames: array [1 .. 6] of string = ('JpgImage_65', 'JpgImage_66',
    'JpgImage_67', 'JpgImage_68', 'JpgImage_69', 'JpgImage_70');

implementation

{$R *.dfm}

function getGameObject(x, y: Integer) : TGameObject;
var I: Integer;
var occupied: Boolean;
begin
occupied := False;
  for I := 0 to Length(gameObjects) - 1 do begin
    if ((gameObjects[I].x = x) and (gameObjects[I].y = y)) then begin
      result := gameObjects[I];
      occupied := True;
    end;

  end;
  if occupied = False then
    result := nil;
end;

procedure addGameObject(x, y: Integer);
var
  newGameObject: TGameObject;
  objectExistsAlready: Boolean;
  I : Integer;
begin
  objectExistsAlready := False;

  for I := 0 to Length(gameObjects) - 1 do begin
    if ((gameObjects[I].x = x) and (gameObjects[I].y = y)) then begin
      objectExistsAlready := True;
      writeln('THAT LOCATION IS OCCUPIED');
    end;

  end;

  if objectExistsAlready <> True then begin
    newGameObject := TGameObject.Create;
    newGameObject.x := x;
    newGameObject.y := y;
    SetLength(gameObjects, Length(gameObjects) + 1);
    gameObjects[ High(gameObjects)] := newGameObject;
  end;


  
end;

procedure setCaption();
begin
  Form3.Caption := 'FPS: ' + inttostr(CURRENTFPS) + ' X: ' + inttostr(PlayerX)
    + ' Y: ' + inttostr(PlayerY) + ' ActualX: ' + inttostr
    (PlayerActualX + PlayerX) + ' ActualY: ' + inttostr
    (PlayerActualY + PlayerY) + ' Distance: ' + floattostr
    (round(Distance))
end;

procedure placeGround();
var
  x, y: Integer;
begin

  // writeln(inttostr(PlayerX) + ' ' + inttostr(Form3.ClientWidth)); 

  Form3.Image1.Picture.Bitmap.Width := Form3.Image1.Width;
  Form3.Image1.Picture.Bitmap.Height := Form3.Image1.Height;

  Form3.LevelImage.Picture.Bitmap.Width := Form3.Image1.Width;
  Form3.LevelImage.Picture.Bitmap.Height := Form3.Image1.Height;

  randseed := Math.Floor((PlayerActualX + PlayerX + 32) / Form3.ClientWidth)
    + Math.Floor((PlayerActualY + PlayerY + 32) / Form3.ClientHeight) + Seed;

  for x := 0 to round(Form3.Image1.Width / 32) do begin
    for y := 0 to round(Form3.Image1.Height / 32) do
      Form3.LevelImage.canvas.Draw(x * 32, y * 32,
        grassTileImages[RandomRange(1, Length(grassTileImages))]);
  end;

end;

procedure TForm3.FormCreate(Sender: TObject);
var
  I: Integer;
  T: TResourceStream;
begin

  AllocConsole;

  oldWindowX := Form3.Left;
  oldWindowY := Form3.Top;

  Form3.Image1.Width := Form3.Width;
  Form3.Image1.Height := Form3.Height;

  Form3.LevelImage.Width := Form3.Width;
  Form3.LevelImage.Height := Form3.Height;

  PlayerX := 0;
  PlayerY := 0;

  PlayerActualX := 0;
  PlayerActualY := 0;

  playerImage := TPngImage.Create;
  selectorImage := TPngImage.Create;
  nopeSelectorImage := TPngImage.Create;
  heartImage := TPngImage.Create;

  T := TResourceStream.Create(hInstance, 'man_01', RT_RCDATA);
  playerImage.LoadFromStream(T);
  T.Free;

  T := TResourceStream.Create(hInstance, 'PngImage_1', RT_RCDATA);
  selectorImage.LoadFromStream(T);
  T.Free;

  T := TResourceStream.Create(hInstance, 'PngImage_18', RT_RCDATA);
  nopeselectorImage.LoadFromStream(T);
  T.Free;

  T := TResourceStream.Create(hInstance, 'PngImage_17', RT_RCDATA);
  heartImage.LoadFromStream(T);
  T.Free;

  for I := 1 to Length(grassTileNames) do begin
    jpg := TJPEGImage.Create;
    T := TResourceStream.Create(hInstance, grassTileNames[I], RT_RCDATA);
    jpg.LoadFromStream(T);
    T.Free;
    grassTileImages[I] := jpg;
  end;

  placeGround;

end;

procedure TForm3.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = Word('W') then
    forwardKey := True;
  if Key = Word('A') then
    leftKey := True;
  if Key = Word('S') then
    backwardKey := True;
  if Key = Word('D') then
    rightKey := True;

end;

procedure TForm3.FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = Word('W') then
    forwardKey := False;
  if Key = Word('A') then
    leftKey := False;
  if Key = Word('S') then
    backwardKey := False;
  if Key = Word('D') then
    rightKey := False;
end;

procedure TForm3.FpsResetTimer(Sender: TObject);
begin
  CURRENTFPS := FPS;
  setCaption;
  if FPS >= 60 then begin
    FPS := 0;
  end;

end;

procedure TForm3.gameLoopTimer(Sender: TObject);
var
  pt: tPoint;
var
  frame: TGraphic;
  I: Integer;
begin

  if forwardKey then begin
    PlayerY := PlayerY - 10;

    if rightKey then begin
      PlayerX := PlayerX - 4;
      PlayerY := PlayerY + 4;
    end;

    if leftKey then begin
      PlayerX := PlayerX + 4;
      PlayerY := PlayerY + 4;
    end;

  end;
  if backwardKey then begin
    PlayerY := PlayerY + 10;

    if rightKey then begin
      PlayerX := PlayerX - 4;
      PlayerY := PlayerY - 4;
    end;

    if leftKey then begin
      PlayerX := PlayerX + 4;
      PlayerY := PlayerY - 4;
    end;

  end;
  if leftKey then begin
    PlayerX := PlayerX - 10;
  end;
  if rightKey then begin
    PlayerX := PlayerX + 10;
  end;

  if PlayerY < -32 then begin // Player Enter Top 
    PlayerActualY := PlayerActualY - Form3.ClientHeight;
    PlayerY := Form3.ClientHeight - 32;
    writeln('Enter Top');
  end
  else if PlayerY > Form3.ClientHeight - 32 then begin // Player Enter Bottom 
    PlayerActualY := PlayerActualY + Form3.ClientHeight;
    PlayerY := -32;
    writeln('Enter Bottom');
  end
  else if PlayerX < -32 then begin // Player Enter Left 
    PlayerX := Form3.ClientWidth - 32;
    PlayerActualX := PlayerActualX - Form3.ClientWidth;
    writeln('Enter Left');
  end
  else if PlayerX > Form3.ClientWidth - 32 then begin // Player Enter Right 
    PlayerX := -32;
    PlayerActualX := PlayerActualX + Form3.ClientWidth;
    writeln('Enter Right');
  end;

  Form3.Image1.canvas.CopyRect(Form3.Image1.canvas.ClipRect,
    Form3.LevelImage.canvas, Form3.LevelImage.canvas.ClipRect);

  for I := 0 to Length(gameObjects) - 1 do begin
    // writeln('OBJECT POSITION'); 
    // writeln(Math.Floor(gameObjects[I].X*32 / form3.ClientWidth)); 
    // writeln(Math.Floor(gameObjects[I].Y*32 / form3.ClientHeight)); 
    // writeln('PLAYER POSITION'); 
    // writeln(Math.Floor(PlayerActualX / form3.ClientWidth)); 
    // writeln(Math.Floor(PlayerActualY / form3.ClientHeight)); 

    playerQuadX := Math.Floor(PlayerActualX / Form3.ClientWidth);
    playerQuadY := Math.Floor(PlayerActualY / Form3.ClientHeight);

    if ((Math.Floor(gameObjects[I].x * 32 / Form3.ClientWidth) = playerQuadX)
        and (Math.Floor(gameObjects[I].y * 32 / Form3.ClientHeight)
          = playerQuadY)) then begin
      Form3.Image1.canvas.Draw((gameObjects[I].x) * 32 - playerQuadX * 32 * 40,
        (gameObjects[I].y) * 32 - playerQuadY * 32 * 20, playerImage);
      // writeln('DRAWING OBJECT!!!!!!!!!!!!!!!!!!!!!'); 
    end;

  end;

  Form3.Image1.canvas.Draw(PlayerX + 16, PlayerY + 16, playerImage);

  placeGround();

  pt := Mouse.CursorPos;
  pt := ScreenToClient(pt);

  cursorGridX := round((pt.x - 16) / 32);
  cursorGridY := round((pt.y - 16) / 32);

  if getGameObject(cursorGridX + playerQuadX * 40, cursorGridY + playerQuadY * 20) <> nil then begin
    Form3.Image1.canvas.Draw(cursorGridX * 32, cursorGridY * 32, nopeSelectorImage);
  end else begin
    Form3.Image1.canvas.Draw(cursorGridX * 32, cursorGridY * 32, selectorImage);
  end;




  for I := 0 to 5 do
    Form3.Image1.canvas.Draw(5, (32 * I) + 5, heartImage);

  // Distance := Sqrt(Sqr(PlayerActualX+PlayerX-pt.x)+Sqr(PlayerActualY+PlayerY-pt.y)); 

  setCaption();

  FPS := FPS + 1;

  // writeln(oldWindowX); 
  // writeln(Form3.Left); 

end;

procedure TForm3.Image1Click(Sender: TObject);
begin
  writeln('placeing');
  addGameObject(cursorGridX + playerQuadX * 40, cursorGridY + playerQuadY * 20);
end;

procedure TForm3.screenBlankTimerTimer(Sender: TObject);
begin

  if ((oldWindowX <> Form3.Left) or (oldWindowY <> Form3.Top)) then begin
    gameLoop.Enabled := False;

    warning.Visible := True;
  end;

  if ((oldWindowX = Form3.Left) and (oldWindowY = Form3.Top)) then begin
    gameLoop.Enabled := True;
    warning.Visible := False;
  end;

  oldWindowX := Form3.Left;
  oldWindowY := Form3.Top;
end;

end.
