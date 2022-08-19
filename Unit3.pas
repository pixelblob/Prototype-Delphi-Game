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
    procedure pauseGame();
    procedure unpauseGame();
    procedure Image1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; x, y: Integer);
    procedure Image1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; x, y: Integer);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form3: TForm3;
  jpg: TJPEGImage;
  png: TGraphic;
  forwardKey, backwardKey, leftKey, rightKey, isMouseDown,
    isLeftMouseDown: Boolean;

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

  Form3.cachedLevel.canvas.pen.color := clwhite;
  Form3.cachedLevel.canvas.brush.color := clwhite;
  Form3.cachedLevel.canvas.rectangle(0, 0, Form3.cachedLevel.width,
    Form3.cachedLevel.height);

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

  objectBitmapCache := TBitmap.create;
  objectBitmapCache.canvas.brush.Handle := 0;
  objectBitmapCache.Transparent := True;

  objectBitmapCache.width := Form3.width;
  objectBitmapCache.height := Form3.height;

  objectBitmapCache.canvas.CopyRect(objectBitmapCache.canvas.ClipRect,
    Form3.cachedLevel.canvas, Form3.cachedLevel.canvas.ClipRect);

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

procedure removeGameObject(x, y: Integer);
var
  ALength: Cardinal;
  I: Integer;
  Iv: Cardinal;
begin

  for I := 0 to Length(gameObjects) - 1 do begin
    if ((gameObjects[I].x = x) and (gameObjects[I].y = y)) then BEGIN

      ALength := Length(gameObjects);
      Assert(ALength > 0);
      Assert(I < ALength);
      for Iv := I + 1 to ALength - 1 do
        gameObjects[Iv - 1] := gameObjects[Iv];
      SetLength(gameObjects, ALength - 1);

    END;
  end;

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
    newGameObject := TGameObject.create;
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

  Form3.Image1.Picture.Bitmap.width := Form3.Image1.width;
  Form3.Image1.Picture.Bitmap.height := Form3.Image1.height;

  Form3.LevelImage.Picture.Bitmap.width := Form3.Image1.width;
  Form3.LevelImage.Picture.Bitmap.height := Form3.Image1.height;

  randseed := Math.Floor((PlayerActualX + PlayerX + 32) / Form3.ClientWidth)
    + Math.Floor((PlayerActualY + PlayerY + 32) / Form3.ClientHeight) + Seed;

  for x := 0 to round(Form3.Image1.width / 32) do begin
    for y := 0 to round(Form3.Image1.height / 32) do
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

  Form3.Image1.width := Form3.width;
  Form3.Image1.height := Form3.height;

  Form3.LevelImage.width := Form3.width;
  Form3.LevelImage.height := Form3.height;

  Form3.cachedLevel.width := Form3.width;
  Form3.cachedLevel.height := Form3.height;

  PlayerX := 0;
  PlayerY := 0;

  PlayerActualX := 0;
  PlayerActualY := 0;

  for I := 1 to Length(gameObjectTextureNames) do begin
    png := TPngImage.create;
    T := TResourceStream.create(hInstance, gameObjectTextureNames[I],
      RT_RCDATA);
    png.LoadFromStream(T);
    T.Free;
    gameObjectTextures[I] := png;
  end;

  for I := 1 to Length(grassTileNames) do begin
    jpg := TJPEGImage.create;
    T := TResourceStream.create(hInstance, grassTileNames[I], RT_RCDATA);
    jpg.LoadFromStream(T);
    T.Free;
    grassTileImages[I] := jpg;
  end;

  playerImage := TPngImage.create;
  selectorImage := TPngImage.create;
  nopeSelectorImage := TPngImage.create;
  heartImage := TPngImage.create;
  pauseScreen := TPngImage.create;

  T := TResourceStream.create(hInstance, 'man_01', RT_RCDATA);
  playerImage.LoadFromStream(T);
  T.Free;

  T := TResourceStream.create(hInstance, 'pause_screen', RT_RCDATA);
  pauseScreen.LoadFromStream(T);
  T.Free;

  T := TResourceStream.create(hInstance, 'PngImage_1', RT_RCDATA);
  selectorImage.LoadFromStream(T);
  T.Free;

  T := TResourceStream.create(hInstance, 'PngImage_18', RT_RCDATA);
  nopeSelectorImage.LoadFromStream(T);
  T.Free;

  T := TResourceStream.create(hInstance, 'PngImage_17', RT_RCDATA);
  heartImage.LoadFromStream(T);
  T.Free;

  for I := 1 to Length(grassTileNames) do begin
    jpg := TJPEGImage.create;
    T := TResourceStream.create(hInstance, grassTileNames[I], RT_RCDATA);
    jpg.LoadFromStream(T);
    T.Free;
    grassTileImages[I] := jpg;
  end;

  placeGround;

  for x := 0 + (5) to 4 + (5) do begin
    for y := 0 + (5) to 4 + (5) do begin
      if ((x = 0 + (5)) or (x = 4 + (5))) then
        addGameObject(x, y, 'brick');

      if ((y = 0 + (5)) or (y = 4 + (5))) then begin
        if ((y = 0 + (5)) and (x = 2 + (5))) then
        else
          addGameObject(x, y, 'brick');

      end;

    end;
  end;

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
  tempcanvas: TCanvas;
  WindowHandle: HWND;
  ScreenDC, bufferDC: HDC;
  PrevX, PrevY: Integer;
begin

  PrevX := PlayerX;
  PrevY := PlayerY;

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

  // Draws the grass
  Form3.Image1.canvas.CopyRect(Form3.Image1.canvas.ClipRect,
    Form3.LevelImage.canvas, Form3.LevelImage.canvas.ClipRect);

  Form3.Image1.canvas.Draw(0, 0, objectBitmapCache);

  Form3.Image1.canvas.Draw(PlayerX + 16, PlayerY + 16, playerImage);

  placeGround();

  pt := Mouse.CursorPos;
  pt := ScreenToClient(pt);

  if (isMouseDown = True) then begin
    if ((cursorGridX <> round((pt.x - 16) / 32)) or
        (cursorGridY <> round((pt.y - 16) / 32))) then begin
      if isLeftMouseDown then begin
        writeln('DRAG-PLACE');
        addGameObject(cursorGridX + playerQuadX * 40,
          cursorGridY + playerQuadY * 20, 'brick');
        addGameObject(round((pt.x - 16) / 32) + playerQuadX * 40,
          round((pt.y - 16) / 32) + playerQuadY * 20, 'brick');
        updateLevelCache;
      end
      else begin
        writeln('DRAG-DELETE');
        removeGameObject(cursorGridX + playerQuadX * 40,
          cursorGridY + playerQuadY * 20);
        removeGameObject(round((pt.x - 16) / 32) + playerQuadX * 40,
          round((pt.y - 16) / 32) + playerQuadY * 20);
        updateLevelCache;
      end;
    end;
  end;

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



  // COLLISON STUFFS

  for I := 0 to Length(gameObjects) - 1 do begin
    if ((Math.Floor(gameObjects[I].x * 32 / Form3.ClientWidth) = playerQuadX)
        and (Math.Floor(gameObjects[I].y * 32 / Form3.ClientHeight)
          = playerQuadY)) then begin

      // writeln((ABS((playerY+32) - gameObjects[I].Y*32)));
      // if ((ABS((playerX) - gameObjects[I].x*32) <= 32) and (ABS((playerY) - gameObjects[I].Y*32) <= 16)) then begin
      // writeln(ABS(playerX - gameObjects[I].x*32));
      if ((ABS(PlayerX+ (playerQuadX * 40 * 32) + 16 - gameObjects[I].x * 32) <= 20) and
          (ABS(PlayerY+ (playerQuadY * 20 * 32) + 16 - gameObjects[I].y * 32) <= 20)) then begin

        PlayerX := PrevX;
        PlayerY := PrevY;

      end;

    end;
  end;



  // for I := 0 to 5 do
  // Form3.Image1.canvas.Draw(5, (32 * I) + 5, heartImage);       HEART STUFF, DONT NEED IT YET...

  setCaption();

  FPS := FPS + 1;

end;

procedure TForm3.Image1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; x, y: Integer);
begin
  isMouseDown := True;

  if Button = mbLeft then
    isLeftMouseDown := True
  else if Button = mbRight then
    isLeftMouseDown := False;

  if isLeftMouseDown then begin
    writeln('PLACE');
    addGameObject(cursorGridX + playerQuadX * 40,
      cursorGridY + playerQuadY * 20, 'brick');
    updateLevelCache;
  end
  else begin
    writeln('DELETE');
    removeGameObject(cursorGridX + playerQuadX * 40,
      cursorGridY + playerQuadY * 20);
    updateLevelCache;
  end;

end;

procedure TForm3.Image1MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; x, y: Integer);
begin
  isMouseDown := False;

  if Button = mbLeft then
    isLeftMouseDown := False
  else if Button = mbRight then
    isLeftMouseDown := False;

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
