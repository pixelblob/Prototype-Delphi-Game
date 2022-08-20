unit Unit3;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, pngimage, ExtCtrls, jpeg, Math, Sockets, DateUtils, StdCtrls,
  gameObjectManagement;

type
  TBerryBush = class(TGameObject)
    growthStage: Integer;
  end;

type

  TForm3 = class(TForm)
    Image1: TImage;
    gameLoop: TTimer;
    LevelImage: TImage;
    FpsReset: TTimer;
    cachedLevel: TImage;
    brightnessMap: TImage;
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
    gameObjects: array of TGameObject;
  end;

var
  Form3: TForm3;
  jpg: TJPEGImage;
  png: TGraphic;
  forwardKey, backwardKey, leftKey, rightKey, isMouseDown,
    isLeftMouseDown: Boolean;

  grassTileImages: array [1 .. 6] of TJPEGImage;
  SelectedSlot: Integer = 0;

  bush, tree1, tree2, tree3, tree4, playerImage, darkImage, selectorImage,
    nopeSelectorImage, heartImage, toolbarImage, pauseScreen: TGraphic;

  PlayerX, PlayerActualX, PlayerY, PlayerActualY, oldWindowX, oldWindowY,
    playerQuadX, playerQuadY, CURRENTFPS, FPS, cursorGridX, cursorGridY,
    paused: Integer;

  objectBitmapCache: TBitmap;

  lightBitmapCache: TPngImage;

  Distance: Real;
  Seed: Integer = 69420;
  gameObjects: array of TGameObject;
  berryBushObjects: array of TBerryBush;
  generatedQuadrents: array of Integer;

const
  gameTextureNames: array [1 .. 8] of string = ('missing', 'selectedSlot',
    'Toolbar', 'pause_screen', 'man_01', 'PngImage_1', 'PngImage_18',
    'PngImage_17');

var
  gameTextures: array [1 .. 8] of TGraphic;
  growthStageTextureNames: array [1 .. 4] of string = (
    'empty_berry_bush',
    '1_third_berry_bush',
    '2_thirds_berry_bush',
    'full_berry_bush'
  );
  gameObjectTypes: array [1 .. 2] of string = (
    'brick',
    'man_01'
  );
  gameObjectTextureNames: array [1 .. 2] of string = (
    'PngImage_19',
    'man_01'
  );

var
  growthStageTextures: array [1 .. 4] of TGraphic;
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

function getTexture(texture: String): TGraphic;
var
  I: Integer;
begin
  // writeln('Requested Texture: '+texture);
  Result := gameTextures[1];
  for I := 1 to Length(gameTextureNames) do begin
    if (gameTextureNames[I] = texture) then begin
      Result := gameTextures[I];
      break;
    end;
  end;
end;

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

  for I := 0 to Length(berryBushObjects) - 1 do begin
    if ((Math.Floor(berryBushObjects[I].x * 32 / Form3.ClientWidth)
          = playerQuadX) and (Math.Floor
          (berryBushObjects[I].y * 32 / Form3.ClientHeight) = playerQuadY))
      then begin

      Form3.cachedLevel.canvas.Draw
        (berryBushObjects[I].x * 32 - playerQuadX * 32 * 40,
        berryBushObjects[I].y * 32 - playerQuadY * 32 * 20,
        growthStageTextures[berryBushObjects[I].growthStage]
        );
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

procedure updateBrightnessCache;
var
  x, y: Integer;
begin

  Form3.brightnessMap.canvas.pen.color := clwhite;
  Form3.brightnessMap.canvas.brush.color := clwhite;
  Form3.brightnessMap.canvas.rectangle(0, 0, Form3.brightnessMap.width,
    Form3.brightnessMap.height);

  for x := 0 to 40 do begin
    for y := 0 to 20 do begin
      Form3.brightnessMap.canvas.Draw(x * 32, y * 32, darkImage)
    end;
  end;

  lightBitmapCache := TPngImage.create;
  lightBitmapCache.canvas.brush.Handle := 0;
  lightBitmapCache.Transparent := True;

  // lightBitmapCache.width := Form3.width;
  // lightBitmapCache.height := Form3.height;

  lightBitmapCache.canvas.CopyRect(lightBitmapCache.canvas.ClipRect,
    Form3.brightnessMap.canvas, Form3.brightnessMap.canvas.ClipRect);

  writeln('UPDATED LIGHT CACHE');
end;

function getBushObject(x, y: Integer): TBerryBush;
var
  I: Integer;
var
  occupied: Boolean;
begin
  occupied := False;
  for I := 0 to Length(berryBushObjects) - 1 do begin
    if ((berryBushObjects[I].x = x) and (berryBushObjects[I].y = y)) then BEGIN
      Result := berryBushObjects[I];
      occupied := True;
    END;
  end;

  if (occupied = False) then
    Result := nil;
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
  newGameObject: TBerryBush;
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

  Form3.brightnessMap.width := Form3.width;
  Form3.brightnessMap.height := Form3.height;

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

  for I := 1 to Length(growthStageTextureNames) do begin
    png := TPngImage.create;
    T := TResourceStream.create(hInstance, growthStageTextureNames[I],
      RT_RCDATA);
    png.LoadFromStream(T);
    T.Free;
    growthStageTextures[I] := png;
  end;

  for I := 1 to Length(grassTileNames) do begin
    jpg := TJPEGImage.create;
    T := TResourceStream.create(hInstance, grassTileNames[I], RT_RCDATA);
    jpg.LoadFromStream(T);
    T.Free;
    grassTileImages[I] := jpg;
  end;

  for I := 1 to Length(gameTextureNames) do begin
    try
      gameTextures[I] := TPngImage.create;
      T := TResourceStream.create(hInstance, gameTextureNames[I], RT_RCDATA);
      gameTextures[I].LoadFromStream(T);
      writeln('Loaded Texture: ' + gameTextureNames[I]);
    except
      writeln('Failed to load: ' + gameTextureNames[I]);
      gameTextures[I] := gameTextures[1];
    end;
    T.Free;
  end;

  playerImage := getTexture('man_01');

  darkImage := getTexture('dark_square');

  pauseScreen := getTexture('pause_screen');

  selectorImage := getTexture('PngImage_1');

  nopeSelectorImage := getTexture('PngImage_18');

  heartImage := getTexture('PngImage_17');

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
        gameObjectManagement.addGameObject(x, y, 'brick');

      if ((y = 0 + (5)) or (y = 4 + (5))) then begin
        if ((y = 0 + (5)) and (x = 2 + (5))) then
        else
          addGameObject(x, y, 'brick');

      end;

    end;
  end;

  newGameObject := TBerryBush.create;
  newGameObject.x := 3;
  newGameObject.y := 4;
  newGameObject.growthStage := 4;
  SetLength(berryBushObjects, Length(berryBushObjects) + 1);
  berryBushObjects[ High(berryBushObjects)] := newGameObject;

  updateLevelCache;
  // updateBrightnessCache;

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
var
  quadGenerated: Boolean;
var
  I: Integer;
  newGameObject: TBerryBush;
begin
  quadGenerated := False;
  playerQuadX := Math.Floor(PlayerActualX / Form3.ClientWidth);
  playerQuadY := Math.Floor(PlayerActualY / Form3.ClientHeight);

  for I := 1 to Length(generatedQuadrents) do begin
    if (generatedQuadrents[I] = Math.Floor((PlayerActualX + PlayerX + 32)
          / Form3.ClientWidth) + Math.Floor((PlayerActualY + PlayerY + 32)
          / Form3.ClientHeight)) then begin

      quadGenerated := True;

    end;
  end;

  if quadGenerated = False then begin
    writeln('GENERATING BERRYS');
    for I := 1 to Random(10) do begin
      newGameObject := TBerryBush.create;
      newGameObject.x := Random(40) + playerQuadX * 40;
      newGameObject.y := Random(20) + playerQuadY * 20;
      newGameObject.growthStage := Random(4) + 1;
      SetLength(berryBushObjects, Length(berryBushObjects) + 1);
      berryBushObjects[ High(berryBushObjects)] := newGameObject;
    end;
  end;

  updateLevelCache;
end;

procedure TForm3.gameLoopTimer(Sender: TObject);
var
  pt: tPoint;
var
  I, speed: Integer;
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

  // Form3.Image1.canvas.Draw(0, 0, lightBitmapCache);

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

  if gameObjectManagement.getGameObject(cursorGridX + playerQuadX * 40,
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
      if ((ABS(PlayerX + (playerQuadX * 40 * 32) + 16 - gameObjects[I].x * 32)
            <= 20) and (ABS(PlayerY + (playerQuadY * 20 * 32)
              + 16 - gameObjects[I].y * 32) <= 20)) then begin

        PlayerX := PrevX;
        PlayerY := PrevY;

      end;

    end;
  end;
  Form3.Image1.canvas.Draw(Form3.ClientWidth - 32,
    round(Form3.ClientHeight / 2) - 5 * 32, getTexture('Toolbar'));

  // for I := 0 to 5 do
  // Form3.Image1.canvas.Draw(5, (32 * I) + 5, heartImage);       HEART STUFF, DONT NEED IT YET...

  setCaption();

  FPS := FPS + 1;

end;

procedure TForm3.Image1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; x, y: Integer);
var
  berryBush: TBerryBush;
begin
  isMouseDown := True;

  if Button = mbLeft then
    isLeftMouseDown := True
  else if Button = mbRight then
    isLeftMouseDown := False;

  if isLeftMouseDown then begin
    berryBush := getBushObject(cursorGridX + playerQuadX * 40,
      cursorGridY + playerQuadY * 20);
    if berryBush <> nil then begin
      writeln('HARVEST');
      if (berryBush.growthStage > 1) then
        berryBush.growthStage := berryBush.growthStage - 1;
    end
    else begin
      writeln('PLACE');
      addGameObject(cursorGridX + playerQuadX * 40,
        cursorGridY + playerQuadY * 20, 'brick');
    end;
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
