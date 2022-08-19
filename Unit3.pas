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
  DateUtils,
  StdCtrls;

type
  TGameObject = class(TObject)
    x, y: Integer;
    objectType: String;
  end;

type

  TForm3 = class(TForm)
    Image1: TImage;
    gameLoop: TTimer;
    LevelImage: TImage;
    FpsReset: TTimer;
    cachedLevel: TImage;
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure gameLoopTimer(Sender: TObject);
    procedure FpsResetTimer(Sender: TObject);
    procedure Image1Click(Sender: TObject);
    procedure pauseGame();
    procedure unpauseGame();
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form3: TForm3;
  jpg: TJPEGImage;
  png: TGraphic;
  forwardKey, backwardKey, leftKey, rightKey: Boolean;

  grassTileImages: array [1 .. 6] of TJPEGImage;
  SelectedSlot: Integer = 0;

  bush, tree1, tree2, tree3, tree4, playerImage, selectorImage,
    nopeSelectorImage, heartImage, pauseScreen: TGraphic;

  PlayerX, PlayerActualX, PlayerY, PlayerActualY, oldWindowX, oldWindowY,
    playerQuadX, playerQuadY, CURRENTFPS, FPS, cursorGridX, cursorGridY,
    paused: Integer;

    objectBitmapCache: TBitmap;

  Distance: Real;
  Seed: Integer = 69420;
  gameObjects: array of TGameObject;

const
  gameObjectTypes: array [1 .. 2] of string = ('brick', 'man_01');
  gameObjectTextureNames: array [1 .. 2] of string = ('PngImage_19', 'man_01');

var
  gameObjectTextures: array [1 .. 2] of TGraphic;

  grassTileNames: array [1 .. 6] of string = (
    'JpgImage_65',
    'JpgImage_66',
    'JpgImage_67',
    'JpgImage_68',
    'JpgImage_69',
    'JpgImage_70'
  );

implementation

{$R *.dfm}

procedure updateLevelCache;
var
  I, R, objectIndex: Integer;
begin

Form3.cachedLevel.canvas.pen.color:=clwhite;
      Form3.cachedLevel.canvas.brush.color:=clwhite;
      Form3.cachedLevel.canvas.rectangle(0,0,form3.cachedLevel.width, form3.cachedLevel.height);

  for I := 0 to Length(gameObjects) - 1 do begin
    if ((Math.Floor(gameObjects[I].x * 32 / Form3.ClientWidth) = playerQuadX)
        and (Math.Floor(gameObjects[I].y * 32 / Form3.ClientHeight)
          = playerQuadY)) then begin
      for R := 1 to Length(gameObjectTypes) do
        if gameObjectTypes[R] = gameObjects[I].objectType then begin
          objectIndex := R;
        end;

      Form3.cachedLevel.canvas.Draw
        (gameObjects[I].x * 32 - playerQuadX * 32 * 40,
        gameObjects[I].y * 32 - playerQuadY * 32 * 20,
        gameObjectTextures[objectIndex]);
    end;
  end;

  objectBitmapCache:= TBitmap.create;
    objectBitmapCache.Canvas.Brush.Handle := 0;
    objectBitmapCache.Transparent := True;

    objectBitmapCache.Width := Form3.Width;
    objectBitmapCache.Height := Form3.Height;

     objectBitmapCache.Canvas.CopyRect(objectBitmapCache.Canvas.ClipRect, form3.cachedLevel.Canvas, form3.cachedLevel.Canvas.ClipRect);

  writeln('UPDATED LEVEL CACHE');
end;

function getGameObject(x, y: Integer): TGameObject;
var
  I: Integer;
var
  occupied: Boolean;
begin
  occupied := False;
  for I := 0 to Length(gameObjects) - 1 do begin
    if ((gameObjects[I].x = x) and (gameObjects[I].y = y)) then BEGIN
      result := gameObjects[I];
      occupied := True;
    END;
  end;

  if (occupied = False) then
    result := nil;
end;

procedure addGameObject(x, y: Integer; objectType: String);
var
  newGameObject: TGameObject;
  objectExistsAlready: Boolean;
  I: Integer;
begin
  objectExistsAlready := False;

  for I := 0 to Length(gameObjects) - 1 do begin
    if ((gameObjects[I].x = x) and (gameObjects[I].y = y)) then BEGIN
      objectExistsAlready := True;
      writeln('THAT LOCATION IS OCCUPIED');
    END;
  end;

  if objectExistsAlready <> True then begin
    newGameObject := TGameObject.Create;
    newGameObject.x := x;
    newGameObject.y := y;
    newGameObject.objectType := objectType;
    SetLength(gameObjects, Length(gameObjects) + 1);
    gameObjects[ High(gameObjects)] := newGameObject;
  end;

end;

procedure setCaption();
begin
  Form3.Caption := 'FPS: ' + IntToStr(CURRENTFPS) + ' X: ' + IntToStr(PlayerX)
    + ' Y: ' + IntToStr(PlayerY) + ' ActualX: ' + IntToStr
    (PlayerActualX + PlayerX) + ' ActualY: ' + IntToStr
    (PlayerActualY + PlayerY) + ' Distance: ' + FloatToStr
    (round(Distance))
end;

procedure placeGround();
var
  x, y: Integer;
begin

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
  I, x, y: Integer;
  T: TResourceStream;
begin

  paused := 1;

  AllocConsole;

  oldWindowX := Form3.Left;
  oldWindowY := Form3.Top;

  Form3.Image1.Width := Form3.Width;
  Form3.Image1.Height := Form3.Height;

  Form3.LevelImage.Width := Form3.Width;
  Form3.LevelImage.Height := Form3.Height;

  Form3.cachedLevel.Width := Form3.Width;
  Form3.cachedLevel.Height := Form3.Height;

  PlayerX := 0;
  PlayerY := 0;

  PlayerActualX := 0;
  PlayerActualY := 0;

  for I := 1 to Length(gameObjectTextureNames) do begin
    png := TPngImage.Create;
    T := TResourceStream.Create(hInstance, gameObjectTextureNames[I],
      RT_RCDATA);
    png.LoadFromStream(T);
    T.Free;
    gameObjectTextures[I] := png;
  end;

  for I := 1 to Length(grassTileNames) do begin
    jpg := TJPEGImage.Create;
    T := TResourceStream.Create(hInstance, grassTileNames[I], RT_RCDATA);
    jpg.LoadFromStream(T);
    T.Free;
    grassTileImages[I] := jpg;
  end;

  playerImage := TPngImage.Create;
  selectorImage := TPngImage.Create;
  nopeSelectorImage := TPngImage.Create;
  heartImage := TPngImage.Create;
  pauseScreen := TPngImage.Create;

  T := TResourceStream.Create(hInstance, 'man_01', RT_RCDATA);
  playerImage.LoadFromStream(T);
  T.Free;

  T := TResourceStream.Create(hInstance, 'pause_screen', RT_RCDATA);
  pauseScreen.LoadFromStream(T);
  T.Free;

  T := TResourceStream.Create(hInstance, 'PngImage_1', RT_RCDATA);
  selectorImage.LoadFromStream(T);
  T.Free;

  T := TResourceStream.Create(hInstance, 'PngImage_18', RT_RCDATA);
  nopeSelectorImage.LoadFromStream(T);
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

  //for x := 0 to 40 do
   // for y := 0 to 20 do
    //  addGameObject(x, y, 'brick');

  updateLevelCache;

end;

procedure TForm3.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = Word('P') then
    updateLevelCache;
  if Key = Word('W') then
    forwardKey := True;
  if Key = Word('A') then
    leftKey := True;
  if Key = Word('S') then
    backwardKey := True;
  if Key = Word('D') then
    rightKey := True;
  if (ord(Key) = 27) then begin // checks for "escape" key press
    INC(paused);
    if ((paused mod 2) = 0) then
      pauseGame
    else
      unpauseGame;
  end;

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
  FPS := 0;
end;

procedure setPlayerQuad;
begin
  playerQuadX := Math.Floor(PlayerActualX / Form3.ClientWidth);
  playerQuadY := Math.Floor(PlayerActualY / Form3.ClientHeight);
  updateLevelCache;
end;

procedure TForm3.gameLoopTimer(Sender: TObject);
var
  pt: tPoint;
var
  frame: TGraphic;
  I, R, speed, objectIndex: Integer;
  Bitmap: TBitmap;
  tempcanvas : TCanvas;
  WindowHandle : HWND;
  ScreenDC,bufferDC : HDC;
begin

  speed := 4;

  if forwardKey then begin
    PlayerY := PlayerY - speed;

    if rightKey then begin
      PlayerX := PlayerX - round(speed / 2);
      PlayerY := PlayerY + round(speed / 2);
    end
    else if leftKey then begin
      PlayerX := PlayerX + round(speed / 2);
      PlayerY := PlayerY + round(speed / 2);
    end;

  end;
  if backwardKey then begin
    PlayerY := PlayerY + speed;

    if rightKey then begin
      PlayerX := PlayerX - round(speed / 2);
      PlayerY := PlayerY - round(speed / 2);
    end
    else if leftKey then begin
      PlayerX := PlayerX + round(speed / 2);
      PlayerY := PlayerY - round(speed / 2);
    end;

  end;
  if leftKey then begin
    PlayerX := PlayerX - speed;
  end;
  if rightKey then begin
    PlayerX := PlayerX + speed;
  end;

  // Player Enter Top of screen
  if PlayerY < -32 then begin
    PlayerActualY := PlayerActualY - Form3.ClientHeight;
    PlayerY := Form3.ClientHeight - 32;
    writeln('Enter Top');
    setPlayerQuad;
  end

  // Player Enter Bottom of screen
  else if PlayerY > Form3.ClientHeight - 32 then begin
    PlayerActualY := PlayerActualY + Form3.ClientHeight;
    PlayerY := -32;
    writeln('Enter Bottom');
    setPlayerQuad;
  end

  // Player Enter LeftHand side of screen
  else if PlayerX < -32 then begin
    PlayerX := Form3.ClientWidth - 32;
    PlayerActualX := PlayerActualX - Form3.ClientWidth;
    writeln('Enter Left');
    setPlayerQuad;
  end

  // Player Enter RightHand side of screen
  else if PlayerX > Form3.ClientWidth - 32 then begin
    PlayerX := -32;
    PlayerActualX := PlayerActualX + Form3.ClientWidth;
    writeln('Enter Right');
    setPlayerQuad;
  end;

  //Draws the grass
  Form3.Image1.canvas.CopyRect(Form3.Image1.canvas.ClipRect,
    Form3.LevelImage.canvas, Form3.LevelImage.canvas.ClipRect);


    Form3.Image1.canvas.Draw(0, 0, objectBitmapCache);

  Form3.Image1.canvas.Draw(PlayerX + 16, PlayerY + 16, playerImage);

  placeGround();

  pt := Mouse.CursorPos;
  pt := ScreenToClient(pt);

  cursorGridX := round((pt.x - 16) / 32);
  cursorGridY := round((pt.y - 16) / 32);

  if getGameObject(cursorGridX + playerQuadX * 40,
    cursorGridY + playerQuadY * 20) <> nil then begin
    Form3.Image1.canvas.Draw(cursorGridX * 32, cursorGridY * 32,
      nopeSelectorImage);
  end
  else begin
    Form3.Image1.canvas.Draw(cursorGridX * 32, cursorGridY * 32, selectorImage);
  end;

  // for I := 0 to 5 do
  // Form3.Image1.canvas.Draw(5, (32 * I) + 5, heartImage);       HEART STUFF, DONT NEED IT YET...

  setCaption();

  FPS := FPS + 1;

end;

procedure TForm3.Image1Click(Sender: TObject);
begin
  writeln('Placing!');
  addGameObject(cursorGridX + playerQuadX * 40, cursorGridY + playerQuadY * 20,
    'brick');
    updateLevelCache;
end;

procedure TForm3.pauseGame;
begin
  gameLoop.enabled := False;
  FpsReset.enabled := False;
  Form3.Image1.canvas.Draw(0, 0, pauseScreen);
end;

procedure TForm3.unpauseGame;
begin
  if (gameLoop.enabled = False) or (FpsReset.enabled = False) then begin
    gameLoop.enabled := True;
    FpsReset.enabled := True;
  end;

end;

end.
