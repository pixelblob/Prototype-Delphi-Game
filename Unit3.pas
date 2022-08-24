unit Unit3;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, pngimage, ExtCtrls, jpeg, Math, Sockets, DateUtils, StdCtrls, superobject,
  gameObjectManagement;

type
  TBerryBush = class(TGameObject)
    growthStage: Integer;
  end;

type
  TPlayer = class(TGameObject)
    x, currentX, y, currentY: Integer;
    id: String;
  end;

type

  TForm3 = class(TForm)
    Image1: TImage;
    gameLoop: TTimer;
    LevelImage: TImage;
    FpsReset: TTimer;
    cachedLevel: TImage;
    TcpClient1: TTcpClient;
    Timer1: TTimer;
    reconnectTimer: TTimer;
    procedure ApplicationMessage(var Msg: tagMSG; var Handled: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure gameLoopTimer(Sender: TObject);
    procedure FpsResetTimer(Sender: TObject);
    procedure pauseGame();
    procedure unpauseGame();
    procedure Image1MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; x, y: Integer);
    procedure Image1MouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; x, y: Integer);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure TcpClient1Receive(Sender: TObject; Buf: PAnsiChar; var DataLen: Integer);
    procedure TcpClient1Error(Sender: TObject; SocketError: Integer);
    procedure Timer1Timer(Sender: TObject);
    procedure reconnectTimerTimer(Sender: TObject);
    procedure TcpClient1Connect(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form3: TForm3;
  jpg: TJPEGImage;
  png: TGraphic;
  forwardKey, backwardKey, leftKey, rightKey, isMouseDown, isLeftMouseDown: Boolean;

  grassTileImages: array [1 .. 6] of TJPEGImage;
  SelectedSlot: Integer = 0;

  bush, tree1, tree2, tree3, tree4, playerImage, playerImage2, connectionImage, no_connectionImage, darkImage, selectorImage, nopeSelectorImage, heartImage, toolbarImage, selectedSlotImage,
    pauseScreen: TGraphic;

  PlayerX, PlayerActualX, PlayerY, frame, PlayerActualY, oldWindowX, oldWindowY, playerQuadX, playerQuadY, CURRENTFPS, FPS, cursorGridX, cursorGridY, paused: Integer;

  objectBitmapCache: TBitmap;

  connection: Boolean;

  Distance: Real;
  Seed: Integer = 69420;
  berryBushObjects: array of TBerryBush;
  players: array of TPlayer;
  generatedQuadrents: array of Integer;

  recieveString, outString: String;

const
  gameTextureNames: array [1 .. 11] of string = ('missing', 'selectedSlot', 'Toolbar', 'pause_screen', 'man_01', 'PngImage_1', 'PngImage_18', 'PngImage_17',
    'man_01_green', 'connection', 'no_connection');

var
  gameTextures: array [1 .. 11] of TGraphic;
  growthStageTextureNames: array [1 .. 4] of string = (
    'empty_berry_bush',
    '1_third_berry_bush',
    '2_thirds_berry_bush',
    'full_berry_bush'
  );
  gameObjectTypes: array [1 .. 3] of string = (
    'brick',
    'man_01',
    'plank'
  );
  gameObjectTextureNames: array [1 .. 3] of string = (
    'PngImage_19',
    'man_01',
    'plank'
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

function getPlayer(id: String): TPlayer;
var
  I: Integer;
begin

  for I := 0 to Length(players) - 1 do begin
    if players[I].id = id then begin
      Result := players[I];
      break;
    end;
  end;

  Result := nil;
end;

function getPlayerIndex(id: String): Integer;
var
  I: Integer;
begin

  for I := 0 to Length(players) - 1 do begin
    if players[I].id = id then begin
      Result := I;
      break;
    end;
  end;

  Result := -1;
end;

function addPlayer(x, y: Integer; id: String): TPlayer;
var
  newPlayer: TPlayer;
begin
  newPlayer := TPlayer.create;
  newPlayer.x := x;
  newPlayer.y := y;
  newPlayer.id := id;
  SetLength(players, Length(players) + 1);
  players[ High(players)] := newPlayer;
  Result := newPlayer;
end;

function deletePlayer(id: String): Boolean;
var
  PlayerIndex: Integer;
  ALength: Cardinal;
  I: Cardinal;
begin

  PlayerIndex := getPlayerIndex(id);

  if PlayerIndex <> -1 then begin

    ALength := Length(players);
    for I := PlayerIndex + 1 to ALength - 1 do
      players[I - 1] := players[I];
    SetLength(players, ALength - 1);

  end
  else
    Result := False;

end;

procedure TForm3.ApplicationMessage(var Msg: tagMSG; var Handled: Boolean);
var
  Window: HWND;
  WinControl: TWinControl;
  Control: TControl;
  Message: TMessage;
begin
  writeln(Msg.message);
  if Msg.message = WM_MOUSEWHEEL then begin
    Window := WindowFromPoint(Msg.pt);
    if Window <> 0 then begin
      WinControl := FindControl(Window);
      if WinControl <> nil then begin
        Control := WinControl.ControlAtPos(WinControl.ScreenToClient(Msg.pt), False);
        if Control <> nil then begin
          Message.WParam := Msg.WParam;
          Message.LParam := Msg.LParam;
          TCMMouseWheel(Message).ShiftState := KeysToShiftState(TWMMouseWheel(Message).Keys);
          Message.Result := Control.Perform(CM_MOUSEWHEEL, Message.WParam, Message.LParam);
          Handled := Message.Result <> 0;
        end;
      end;
    end;
  end;

end;

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

function seedFromQuad: Integer;
var
  Asc: Integer;
begin

  Asc := round((Sin(playerQuadX) + tan(playerQuadY)) * 1000)+Seed;
  // writeln('Seed: ' + inttostr(Asc));
  Result := Asc;

end;

procedure updateLevelCache;
var
  I, R, objectIndex: Integer;
begin

  Form3.cachedLevel.canvas.pen.color := clwhite;
  Form3.cachedLevel.canvas.brush.color := clwhite;
  Form3.cachedLevel.canvas.rectangle(0, 0, Form3.cachedLevel.width, Form3.cachedLevel.height);

  for I := 0 to Length(gameObjects) - 1 do begin
    if ((Math.Floor(gameObjects[I].x * 32 / Form3.ClientWidth) = playerQuadX) and (Math.Floor(gameObjects[I].y * 32 / Form3.ClientHeight) = playerQuadY)) then
      begin
      for R := 1 to Length(gameObjectTypes) do
        if gameObjectTypes[R] = gameObjects[I].objectType then begin
          objectIndex := R;
        end;

      Form3.cachedLevel.canvas.Draw(gameObjects[I].x * 32 - playerQuadX * 32 * 40, gameObjects[I].y * 32 - playerQuadY * 32 * 20,
        gameObjectTextures[objectIndex]);
    end;
  end;

  for I := 0 to Length(berryBushObjects) - 1 do begin
    if ((Math.Floor(berryBushObjects[I].x * 32 / Form3.ClientWidth) = playerQuadX) and (Math.Floor(berryBushObjects[I].y * 32 / Form3.ClientHeight)
          = playerQuadY)) then begin

      Form3.cachedLevel.canvas.Draw(berryBushObjects[I].x * 32 - playerQuadX * 32 * 40, berryBushObjects[I].y * 32 - playerQuadY * 32 * 20,
        growthStageTextures[berryBushObjects[I].growthStage]);
    end;
  end;

  objectBitmapCache := TBitmap.create;
  objectBitmapCache.canvas.brush.Handle := 0;
  objectBitmapCache.Transparent := True;

  objectBitmapCache.width := Form3.width;
  objectBitmapCache.height := Form3.height;

  objectBitmapCache.canvas.CopyRect(objectBitmapCache.canvas.ClipRect, Form3.cachedLevel.canvas, Form3.cachedLevel.canvas.ClipRect);

  writeln('UPDATED LEVEL CACHE');
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
  Form3.Caption := 'FPS: ' + inttostr(CURRENTFPS) + ' X: ' + inttostr(PlayerX) + ' Y: ' + inttostr(PlayerY) + ' ActualX: ' + inttostr(PlayerActualX + PlayerX)
    + ' ActualY: ' + inttostr(PlayerActualY + PlayerY) + ' Quad: (' + inttostr(playerQuadX) + ';' + inttostr(playerQuadY) + ')' + ' Seed: ' + inttostr
    (seedFromQuad) + ' GQ: ' + inttostr(Length(generatedQuadrents)) + ' ' + BoolToStr(Form3.TcpClient1.Active);
end;

procedure placeGround();
var
  x, y: Integer;
begin

  Form3.Image1.Picture.Bitmap.width := Form3.Image1.width;
  Form3.Image1.Picture.Bitmap.height := Form3.Image1.height;

  Form3.LevelImage.Picture.Bitmap.width := Form3.Image1.width;
  Form3.LevelImage.Picture.Bitmap.height := Form3.Image1.height;

  randseed := Math.Floor((PlayerActualX + PlayerX + 32) / Form3.ClientWidth) + Math.Floor((PlayerActualY + PlayerY + 32) / Form3.ClientHeight) + Seed;

  for x := 0 to round(Form3.Image1.width / 32) do begin
    for y := 0 to round(Form3.Image1.height / 32) do
      Form3.LevelImage.canvas.Draw(x * 32, y * 32, grassTileImages[RandomRange(1, Length(grassTileImages))]);
  end;

end;

procedure setPlayerQuad;
var
  quadGenerated: Boolean;
var
  I, Seed: Integer;
  newGameObject: TBerryBush;
begin
  quadGenerated := False;
  playerQuadX := Math.Floor(PlayerActualX / Form3.ClientWidth);
  playerQuadY := Math.Floor(PlayerActualY / Form3.ClientHeight);

  for I := 1 to Length(generatedQuadrents) do begin
    writeln(generatedQuadrents[I]);
    if (generatedQuadrents[I] = seedFromQuad) then begin
      writeln('FOUND QUAD');
      quadGenerated := True;

    end;
  end;

  if quadGenerated = False then begin
    writeln('GENERATING BERRYS');
    SetLength(generatedQuadrents, Length(generatedQuadrents) + 1);
    Seed := seedFromQuad;
    generatedQuadrents[ High(generatedQuadrents)] := Seed;
    randseed := Seed;
    writeln(Seed);
    for I := 1 to Random(10) + 2 do begin
      newGameObject := TBerryBush.create;
      newGameObject.x := Random(40) + playerQuadX * 40;
      newGameObject.y := Random(20) + playerQuadY * 20;
      newGameObject.growthStage := Random(4) + 1;
      SetLength(berryBushObjects, Length(berryBushObjects) + 1);
      berryBushObjects[ High(berryBushObjects)] := newGameObject;
    end;
  end
  else
    writeln('Seed for quad has already been generated: ' + inttostr(generatedQuadrents[Length(generatedQuadrents)]));

  updateLevelCache;
end;

procedure saveGame;
var
  saveGameFile: textFile;
var
  I: Integer;
begin
  AssignFile(saveGameFile, 'data.txt');
  Rewrite(saveGameFile);
  for I := 0 to Length(gameObjects) - 1 do begin
    writeln(saveGameFile, gameObjects[I].x);
    writeln(saveGameFile, gameObjects[I].y);
    writeln(saveGameFile, gameObjects[I].objectType);
    writeln(saveGameFile);
  end;
  Closefile(saveGameFile)
end;

procedure loadGame;
var
  saveGameFile: textFile;
var
  I, x, y: Integer;
  sLine, objectType: String;
begin
  if FileExists('data.txt') then begin
    AssignFile(saveGameFile, 'data.txt');
    Reset(saveGameFile);

    I := 0;

    while not eof(saveGameFile) do begin
      readln(saveGameFile, sLine);

      case I of
        0:
          x := strtoint(sLine);
        1:
          y := strtoint(sLine);
        2:
          objectType := sLine;
      end;

      I := I + 1;
      if I > 3 then begin
        I := 0;
        // addGameObject(x, y, objectType);
        // writeln('Loaded: ' + objectType + ' at x: ' + inttostr(x) + ' y: ' + inttostr(y));
      end;

    end;

    Closefile(saveGameFile);
  end;

end;

procedure TForm3.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  saveGame;
end;

procedure TForm3.FormCreate(Sender: TObject);
var
  I: Integer;
  T: TResourceStream;
begin

  paused := 1;

  AllocConsole;

  connection := True;
  frame := 0;

  TcpClient1.Active := True;

  loadGame;

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
    T := TResourceStream.create(hInstance, gameObjectTextureNames[I], RT_RCDATA);
    png.LoadFromStream(T);
    T.Free;
    gameObjectTextures[I] := png;
  end;

  for I := 1 to Length(growthStageTextureNames) do begin
    png := TPngImage.create;
    T := TResourceStream.create(hInstance, growthStageTextureNames[I], RT_RCDATA);
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
  connectionImage := getTexture('connection');
  no_connectionImage := getTexture('no_connection');
  playerImage2 := getTexture('man_01_green');

  darkImage := getTexture('dark_square');

  pauseScreen := getTexture('pause_screen');

  selectorImage := getTexture('PngImage_1');

  nopeSelectorImage := getTexture('PngImage_18');

  heartImage := getTexture('PngImage_17');
  selectedSlotImage := getTexture('selectedSlot');

  for I := 1 to Length(grassTileNames) do begin
    jpg := TJPEGImage.create;
    T := TResourceStream.create(hInstance, grassTileNames[I], RT_RCDATA);
    jpg.LoadFromStream(T);
    T.Free;
    grassTileImages[I] := jpg;
  end;

  placeGround;

  setPlayerQuad;

  updateLevelCache;

  // addPlayer(100, 100, 'Test')

end;

procedure TForm3.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
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
  if (Ord(Key) = 27) then begin // checks for "escape" key press
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

procedure tryMove(x, y: Integer);
var
  I: Integer;
begin
  PlayerX := PlayerX + x;
  PlayerY := PlayerY + y;

  for I := 0 to Length(gameObjects) - 1 do begin
    if ((Math.Floor(gameObjects[I].x * 32 / Form3.ClientWidth) = playerQuadX) and (Math.Floor(gameObjects[I].y * 32 / Form3.ClientHeight) = playerQuadY)) then
      begin

      if (gameObjects[I].objectType = 'brick') then begin

        if ((ABS(PlayerX + (playerQuadX * 40 * 32) + 16 - gameObjects[I].x * 32) <= 20) and
            (ABS(PlayerY + (playerQuadY * 20 * 32) + 16 - gameObjects[I].y * 32) <= 20)) then begin

          PlayerX := PlayerX - x;
          PlayerY := PlayerY - y;

        end;

      end;

    end;
  end;

end;

function lerp(start, endN, amt: Real): Real;
begin
  Result := (1 - amt) * start + amt * endN;
end;

procedure TForm3.gameLoopTimer(Sender: TObject);
var
  pt: tPoint;
  Bmp: TBitmap;
var
  I, speed, x, y: Integer;
  PrevX, PrevY: Integer;
begin

  PrevX := PlayerX;
  PrevY := PlayerY;

  speed := 4;

  if forwardKey then
    tryMove(0, -speed);

  if backwardKey then
    tryMove(0, speed);

  if leftKey then
    tryMove(-speed, 0);

  if rightKey then
    tryMove(speed, 0);

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
  Form3.Image1.canvas.CopyRect(Form3.Image1.canvas.ClipRect, Form3.LevelImage.canvas, Form3.LevelImage.canvas.ClipRect);

  Form3.Image1.canvas.Draw(0, 0, objectBitmapCache);

  Form3.Image1.canvas.Draw(PlayerX + 16, PlayerY + 16, playerImage);
  for I := 0 to Length(players) - 1 do begin

    players[I].x := round(lerp(players[I].currentX, players[I].x, 0.92));
    players[I].y := round(lerp(players[I].currentY, players[I].y,0.92));

    if ((Math.Floor(players[I].x / (40 * 32)) = playerQuadX) and (Math.Floor(players[I].y / (20 * 32)) = playerQuadY)) then begin
      Form3.Image1.canvas.Draw(players[I].x - playerQuadX * 40 * 32, players[I].y - playerQuadY * 20 * 32, playerImage2);
    end
    else begin
      with Form3.Image1 do begin
        canvas.pen.color := clGreen;
        canvas.pen.width := 1;
        canvas.MoveTo(players[I].x - playerQuadX * 40 * 32, players[I].y - playerQuadY * 20 * 32);
        canvas.LineTo(PlayerX + 32, PlayerY + 32);
      end;
    end;
  end;

  placeGround();

  pt := Mouse.CursorPos;
  pt := ScreenToClient(pt);

  if (isMouseDown = True) then begin
    if ((cursorGridX <> round((pt.x - 16) / 32)) or (cursorGridY <> round((pt.y - 16) / 32))) then begin
      if isLeftMouseDown then begin
        writeln('DRAG-PLACE');

        addServerObject(cursorGridX + playerQuadX * 40, cursorGridY + playerQuadY * 20, 'brick');
        addServerObject(round((pt.x - 16) / 32) + playerQuadX * 40, round((pt.y - 16) / 32) + playerQuadY * 20, gameObjectTypes[SelectedSlot + 1]);

        addGameObject(cursorGridX + playerQuadX * 40, cursorGridY + playerQuadY * 20, 'brick');
        addGameObject(round((pt.x - 16) / 32) + playerQuadX * 40, round((pt.y - 16) / 32) + playerQuadY * 20, gameObjectTypes[SelectedSlot + 1]);
        updateLevelCache;
      end
      else begin
        writeln('DRAG-DELETE');
        removeGameObject(cursorGridX + playerQuadX * 40, cursorGridY + playerQuadY * 20);
        destroyServerObject(cursorGridX + playerQuadX * 40, cursorGridY + playerQuadY * 20);
        removeGameObject(round((pt.x - 16) / 32) + playerQuadX * 40, round((pt.y - 16) / 32) + playerQuadY * 20);
        destroyServerObject(round((pt.x - 16) / 32) + playerQuadX * 40, round((pt.y - 16) / 32) + playerQuadY * 20);
        updateLevelCache;
      end;
    end;
  end;

  cursorGridX := round((pt.x - 16) / 32);
  cursorGridY := round((pt.y - 16) / 32);

  Bmp := TBitmap.Create;
  bmp.Canvas.Brush.Color := clBlack;

  Bmp.Width := 32;
  Bmp.Height := 32;

  //writeln(); // 0 - 1  125 * range


  for X := 0 to 40 do                 //sqrt(sqr(x*32-playerX-16)+sqr(y*32-playery-16))
    for Y := 0 to 20 do
      Form3.Image1.Canvas.Draw(x*32, y*32, bmp, Max(0, min(round((sqrt(sqr(x*32-cursorGridX*32-16)+sqr(y*32-cursorGridY*32-16))/2)),round(125*((sin(frame/1000)+1)/2))))+
        Max(0, min(round((sqrt(sqr(x*32-playerX-16)+sqr(y*32-playerY-16))/2)),round(125*((sin(frame/1000)+1)/2)))));



  bmp.Free;

  if gameObjectManagement.getGameObject(cursorGridX + playerQuadX * 40, cursorGridY + playerQuadY * 20) <> nil then begin
    Form3.Image1.canvas.Draw(cursorGridX * 32, cursorGridY * 32, nopeSelectorImage);
  end
  else begin
    Form3.Image1.canvas.Draw(cursorGridX * 32, cursorGridY * 32, selectorImage);
  end;

  Form3.Image1.canvas.Draw(Form3.ClientWidth - 32, round(Form3.ClientHeight / 2) - 5 * 32, getTexture('Toolbar'));

  Form3.Image1.canvas.Draw(Form3.ClientWidth - 26, (round(Form3.ClientHeight / 2) - 5 * 32) + 12 + (23 * SelectedSlot), selectedSlotImage);


  for I := 0 to 2 do begin

    Form3.Image1.canvas.StretchDraw(Rect(Form3.ClientWidth - 25, (round(Form3.ClientHeight / 2) - 5 * 32) + 12 + (23 * I), Form3.ClientWidth - 26 + 18,
        (round(Form3.ClientHeight / 2) - 5 * 32) + 12 + (23 * I) + 18), gameObjectTextures[I + 1]);

  end;

  Form3.Image1.Canvas.Brush.Style:=bsClear;
    Form3.Image1.Canvas.Font.Style := [fsItalic];

  if connection = True then begin
  Form3.Image1.Canvas.Font.Color:=clWhite;
    Form3.Image1.Canvas.Draw(Form3.ClientWidth-16-(5), 0+(5), connectionImage);
    Form3.Image1.Canvas.TextOut(Form3.ClientWidth-16-(141), 6, 'Connected to gameserver!');
  end
  else begin
  Form3.Image1.Canvas.Font.Color:=clYellow;
    Form3.Image1.Canvas.Draw(Form3.ClientWidth-16-(5), 0+(5), no_connectionImage);
    Form3.Image1.Canvas.TextOut(Form3.ClientWidth-16-(81), 6, 'No Connection');
  end;






  TcpClient1.Receiveln;

  setCaption();

  frame := frame +1;

  FPS := FPS + 1;

end;

procedure TForm3.Image1MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; x, y: Integer);
var
  berryBush: TBerryBush;
  I: Integer;
  slotSelect: Boolean;
begin
  isMouseDown := True;
  slotSelect := False;

  for I := 0 to 12 do begin
    if ((x >= Form3.ClientWidth - 26) and (x <= Form3.ClientWidth - 26 + 320)) then
      if ((y >= (round(Form3.ClientHeight / 2) - 5 * 32) + 12 + (23 * I))) and ((y <= (round(Form3.ClientHeight / 2) - 5 * 32) + 12 + (23 * I) + 20)) then begin
        writeln('Selected Slot: ' + inttostr(I));
        SelectedSlot := I;
        slotSelect := True;
      end;

  end;

  if Button = mbLeft then
    isLeftMouseDown := True
  else if Button = mbRight then
    isLeftMouseDown := False;

  if slotSelect <> True then begin
    if isLeftMouseDown then begin
      berryBush := getBushObject(cursorGridX + playerQuadX * 40, cursorGridY + playerQuadY * 20);
      if berryBush <> nil then begin
        writeln('HARVEST');
        if (berryBush.growthStage > 1) then
          berryBush.growthStage := berryBush.growthStage - 1;
      end
      else begin
        writeln('PLACE');
        addServerObject(cursorGridX + playerQuadX * 40, cursorGridY + playerQuadY * 20, gameObjectTypes[SelectedSlot + 1]);
        addGameObject(cursorGridX + playerQuadX * 40, cursorGridY + playerQuadY * 20, gameObjectTypes[SelectedSlot + 1]);
      end;
      updateLevelCache;
    end
    else begin
      writeln('DELETE');
      removeGameObject(cursorGridX + playerQuadX * 40, cursorGridY + playerQuadY * 20);
      destroyServerObject(cursorGridX + playerQuadX * 40, cursorGridY + playerQuadY * 20);
      updateLevelCache;
    end;

  end;

end;

procedure TForm3.Image1MouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; x, y: Integer);
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

procedure TForm3.reconnectTimerTimer(Sender: TObject);
begin
TcpClient1.Disconnect;
TcpClient1.Connect;
reconnectTimer.Enabled := False;
writeln('Attempting to reconnect!');
connection := True;
end;

procedure TForm3.TcpClient1Connect(Sender: TObject);
begin
writeln('CLIENT HAS CONNECTED');
end;

procedure TForm3.TcpClient1Error(Sender: TObject; SocketError: Integer);
begin

  if ((socketError = 10057) or (socketError = 10054)) then begin
  connection := False;
    reconnectTimer.Enabled := True;
  end
  else if (SocketError <> 10035) then
    writeln(SocketError);
end;

procedure TForm3.TcpClient1Receive(Sender: TObject; Buf: PAnsiChar; var DataLen: Integer);
var
  data, event: String;
var
  I: Integer;
  serverPlayers: ISuperArray;
  x: ISuperObject;
begin
  data := Buf;

  if (data[Length(data)] = ';') then begin
    outString := recieveString + data;

    while (POS(';', outString) <> 0) do begin
      writeln('Recieved Full String: '+Copy(outString, 0, POS(';', outString)));


            x := SO(Copy(outString, 0, POS(';', outString) - 1));
      event := x['event'].AsString;

      if event = 'Ready' then begin
        writeln('Connected to GameServer Successfully!');
        TcpClient1.Sendln('{"event": "movement", "x": ' + inttostr(PlayerX + PlayerActualX) + ', "y": ' + inttostr(PlayerY + PlayerActualY) + '};')
      end
      else if event = 'playersUpdate' then begin
        serverPlayers := x['players'].AsArray;
        for I := 0 to serverPlayers.Length - 1 do begin
          if (getPlayer(serverPlayers[I].O['id'].AsString) = nil) then begin
            writeln('Creating Player: ' + serverPlayers[I].O['id'].AsString);
            addPlayer(serverPlayers[I].O['x'].AsInteger, serverPlayers[I].O['y'].AsInteger, serverPlayers[I].O['id'].AsString);
          end;
        end;
      end
      else if event = 'updateGameObjects' then begin

        SetLength(gameObjects, 0);

        for I := 0 to x['gameObjects'].AsArray.Length - 1 do begin
          addGameObject(x['gameObjects'].AsArray[I].O['x'].AsInteger, x['gameObjects'].AsArray[I].O['y'].AsInteger,
            x['gameObjects'].AsArray[I].O['objectType'].AsString);
        end;
        updateLevelCache;
      end

      else if event = 'movement' then begin

        for I := 0 to Length(players) - 1 do begin
          if players[I].id = x['id'].AsString then begin
            players[I].currentX := x['x'].AsInteger;
            players[I].currentY := x['y'].AsInteger;
          end;
        end;
      end
      else if event = 'modifyServerObject' then begin
        if (x['method'].AsString = 'create') then begin
          addGameObject(x['x'].AsInteger, x['y'].AsInteger, x['objectType'].AsString);
          updateLevelCache;
        end;
        if (x['method'].AsString = 'destroy') then begin
          removeGameObject(x['x'].AsInteger, x['y'].AsInteger);
          updateLevelCache;
        end;
      end;


      outString := Copy(outString, POS(';', outString) + 1);
    end;
    recieveString := '';

  end
  else
    recieveString := recieveString + data;
end;

procedure TForm3.Timer1Timer(Sender: TObject);
begin
  TcpClient1.Sendln('{"event": "movement", "x": ' + inttostr(PlayerX + PlayerActualX) + ', "y": ' + inttostr(PlayerY + PlayerActualY) + '};');
end;

procedure TForm3.unpauseGame;
begin
  if (gameLoop.enabled = False) or (FpsReset.enabled = False) then begin
    gameLoop.enabled := True;
    FpsReset.enabled := True;
  end;

end;

end.
