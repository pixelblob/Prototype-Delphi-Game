unit gameObjectManagement;

interface

type
  TGameObject = class(TObject)
    x, y: Integer;
    objectType: String;
  end;

  var gameObjects: array of TGameObject;

procedure removeGameObject(x, y: Integer);
procedure addGameObject(x, y: Integer; objectType: String);
procedure addServerObject(x, y: Integer; objectType: String);
procedure destroyServerObject(x, y: Integer);
function getGameObject(x, y: Integer): TGameObject;

implementation
uses Unit3, superobject;

function getGameObject(x, y: Integer): TGameObject;
var
  I: Integer;
var
  occupied: Boolean;
begin
  occupied := False;
  for I := 0 to Length(gameObjects) - 1 do begin
    if ((gameObjects[I].x = x) and (gameObjects[I].y = y)) then BEGIN
      Result := gameObjects[I];
      occupied := True;
    END;
  end;

  if (occupied = False) then
    Result := nil;
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
      for Iv := I + 1 to ALength - 1 do
        gameObjects[Iv - 1] := gameObjects[Iv];
        SetLength(gameObjects, ALength - 1);

    END;
  end;

end;

procedure destroyServerObject(x, y: Integer);
var
  newGameObject: TGameObject;
  objectExistsAlready: Boolean;
  I: Integer;
  Xobject: ISuperObject;
begin
 Xobject := TSuperObject.Create;

 //Xobject.V['gameObjects'] := objectArray;
 Xobject.V['event'] := 'modifyServerObject';
 Xobject.V['method'] := 'destroy'; //Allowed methods are create, destroy and modify
 Xobject.V['x'] := x;
 Xobject.V['y'] := y;

 Form3.TcpClient1.Sendln(Xobject.AsString+';')

end;

procedure addServerObject(x, y: Integer; objectType: String);
var
  newGameObject: TGameObject;
  objectExistsAlready: Boolean;
  I: Integer;
  Xobject: ISuperObject;
begin
 Xobject := TSuperObject.Create;

 //Xobject.V['gameObjects'] := objectArray;
 Xobject.V['event'] := 'modifyServerObject';
 Xobject.V['method'] := 'create'; //Allowed methods are create, destroy and modify
 Xobject.V['x'] := x;
 Xobject.V['y'] := y;
 Xobject.V['objectType'] := objectType;

 Form3.TcpClient1.Sendln(Xobject.AsString+';')

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

end.
