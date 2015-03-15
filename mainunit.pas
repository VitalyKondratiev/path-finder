unit mainUnit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, Grids,
  StdCtrls, ExtCtrls;

type

  { TmainForm }

  TmainForm = class(TForm)
    additionGroupBox: TGroupBox;
    allToWallButton: TButton;
    loadDialog: TOpenDialog;
    saveButton: TButton;
    loadButton: TButton;
    saveDialog: TSaveDialog;
    similarLabeledEdit: TLabeledEdit;
    stepsLabeledEdit: TLabeledEdit;
    previewCheckBox: TCheckBox;
    clearButton: TButton;
    currentLabeledEdit: TLabeledEdit;
    findButton: TButton;
    fieldDrawGrid: TDrawGrid;
    fastestLabeledEdit: TLabeledEdit;
    stopButton: TButton;
    procedure allToWallButtonClick(Sender: TObject);
    procedure clearButtonClick(Sender: TObject);
    procedure fieldDrawGridDrawCell(Sender: TObject; aCol, aRow: integer;
      aRect: TRect; aState: TGridDrawState);
    procedure fieldDrawGridMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: integer);
    procedure findButtonClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure loadButtonClick(Sender: TObject);
    procedure saveButtonClick(Sender: TObject);
    procedure setDirectionsWeight(startPoint, finishPoint: TPoint);
    procedure recursiveSearch(playerPosition: TPoint; step: integer;
      positions: array of TPoint);
    procedure stopButtonClick(Sender: TObject);
  private
  var
    playerPlaced, gatePlaced: boolean;
    playerPosition, gatePosition, currentScanPosition: TPoint;
    pathPositions, pathFastest: array of TPoint;
    map: array [1..20, 1..20] of integer;
    directions: array[1..4] of integer;
    item, fastestStepsCount, stepsCount: integer;
    stopRecursion, findState: boolean;
  public
    { public declarations }
  end;

var
  mainForm: TmainForm;

implementation

{$R *.lfm}

{ TmainForm }

procedure TmainForm.FormShow(Sender: TObject);
var
  i, j: integer;
begin
  item := 0;
  fastestStepsCount := 0;
  SetLength(pathFastest, 0);
  playerPosition := Point(-1, -1);
  gatePosition := Point(-1, -1);
  playerPlaced := False;
  gatePlaced := False;
  currentScanPosition := Point(0, 0);
  for i := 1 to 20 do
    for j := 1 to 20 do
      map[i, j] := 0;
end;

procedure TmainForm.fieldDrawGridMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: integer);
var
  thisCell: TPoint;
begin
  if (findState) then
    Exit;
  SetLength(pathFastest, 0);
  thisCell.X := 0;
  thisCell.Y := 0;
  fieldDrawGrid.MouseToCell(X, Y, thisCell.X, thisCell.Y);
  thisCell.X := thisCell.X + 1;
  thisCell.Y := thisCell.Y + 1;
  case Button of
    mbLeft:
    begin
      map[thisCell.X, thisCell.Y] := 1;
      if ((thisCell.X = playerPosition.X) and (thisCell.Y = playerPosition.Y)) then
      begin
        playerPosition := Point(-1, -1);
        playerPlaced := False;
      end;
    end;
    mbRight:
    begin
      map[thisCell.X, thisCell.Y] := 0;
      if ((thisCell.X = gatePosition.X) and (thisCell.Y = gatePosition.Y)) then
      begin
        gatePosition := Point(-1, -1);
        gatePlaced := False;
      end;
    end;
    mbMiddle:
    begin
      if (item <> 2) then
      begin
        gatePlaced := True;
        map[playerPosition.X, playerPosition.Y] := 0;
        map[thisCell.X, thisCell.Y] := 2;
        playerPosition := Point(thisCell.X, thisCell.Y);
        item := 2;
      end
      else
      begin
        playerPlaced := True;
        map[gatePosition.X, gatePosition.Y] := 0;
        map[thisCell.X, thisCell.Y] := 3;
        gatePosition := Point(thisCell.X, thisCell.Y);
        item := 3;
      end;
    end;
  end;
  fieldDrawGrid.Repaint;
  findButton.Enabled := (playerPlaced and gatePlaced);
end;

procedure TmainForm.fieldDrawGridDrawCell(Sender: TObject; aCol, aRow: integer;
  aRect: TRect; aState: TGridDrawState);
var
  i, j, k: integer;
begin
  for i := 1 to 20 do
    for j := 1 to 20 do
    begin
      case map[i][j] of
        0: fieldDrawGrid.Canvas.Brush.Color := clWhite;
        1: fieldDrawGrid.Canvas.Brush.Color := clTeal;
        2: fieldDrawGrid.Canvas.Brush.Color := clGreen;
        3: fieldDrawGrid.Canvas.Brush.Color := clRed;
      end;
      for k := 0 to Length(pathFastest) - 1 do
        if ((i = pathFastest[k].X) and (j = pathFastest[k].Y)) then
          fieldDrawGrid.Canvas.Brush.Color := clMoneyGreen;
      for k := 0 to Length(pathPositions) - 1 do
      begin
        if ((i = pathPositions[k].X) and (j = pathPositions[k].Y)) then
        begin
          fieldDrawGrid.Canvas.Brush.Color := clSkyBlue;
          if ((k <= Length(pathFastest)) and (Length(pathFastest) <> 0)) then
            if ((pathPositions[k].X = pathFastest[k].X) and
              (pathPositions[k].Y = pathFastest[k].Y)) then
            begin
              fieldDrawGrid.Canvas.Brush.Color := clActiveCaption;
            end;
        end;
      end;
      if ((i = currentScanPosition.X) and (j = currentScanPosition.Y)) then
        fieldDrawGrid.Canvas.Brush.Color := clHotLight;
      fieldDrawGrid.Canvas.FillRect(fieldDrawGrid.CellRect(i - 1, j - 1));
    end;
end;

procedure TmainForm.clearButtonClick(Sender: TObject);
var
  i, j: integer;
begin
  item := 0;
  playerPosition := Point(-1, -1);
  gatePosition := Point(-1, -1);
  playerPlaced := False;
  gatePlaced := False;
  for i := 1 to 20 do
    for j := 1 to 20 do
      map[i, j] := 0;
  SetLength(pathFastest, 0);
  currentScanPosition := Point(0, 0);
  fieldDrawGrid.Repaint;
  findButton.Enabled := False;
end;

procedure TmainForm.allToWallButtonClick(Sender: TObject);
var
  i, j: integer;
begin
  for i := 1 to 20 do
    for j := 1 to 20 do
      map[i, j] := 1;
  fieldDrawGrid.Repaint;
end;

procedure TmainForm.findButtonClick(Sender: TObject);
var
  positions: array of TPoint;

  procedure prepareFinding;
  begin
    similarLabeledEdit.Text := 'Не вычислен';
    fastestStepsCount := -1;
    stepsCount := 0;
    stepsLabeledEdit.Text := '-';
    SetLength(pathFastest, 0);
    SetLength(positions, 0);
    stopRecursion := False;
    findButton.Enabled := False;
    stopButton.Enabled := True;
    clearButton.Enabled := False;
    additionGroupBox.Enabled := False;
    findState := True;
  end;

  procedure postFinding;
  begin
    currentScanPosition := Point(0, 0);
    fieldDrawGrid.Repaint;
    findButton.Enabled := True;
    findState := False;
    stopButton.Enabled := False;
    clearButton.Enabled := True;
    additionGroupBox.Enabled := True;
  end;

begin
  prepareFinding;
  setDirectionsWeight(playerPosition, gatePosition);
  recursiveSearch(playerPosition, 0, positions);
  postFinding;
end;

procedure TmainForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  stopRecursion := True;
end;

procedure TmainForm.setDirectionsWeight(startPoint, finishPoint: TPoint);
var
  vectorPoint: TPoint;
begin
  directions[1] := 1;
  directions[2] := 2;
  directions[3] := 3;
  directions[4] := 4;
  vectorPoint := Point(finishPoint.x - startPoint.x, finishPoint.y - startPoint.y);
  if ((vectorPoint.x > 0) and (vectorPoint.y > 0)) then
  begin
    if (abs(vectorPoint.x) > abs(vectorPoint.y)) then
    begin
      directions[1] := 2;
      directions[2] := 3;
      directions[3] := 1;
      directions[4] := 4;
    end
    else
    begin
      directions[1] := 3;
      directions[2] := 2;
      directions[3] := 4;
      directions[4] := 1;
    end;
    exit;
  end;
  if ((vectorPoint.x < 0) and (vectorPoint.y < 0)) then
  begin
    if (abs(vectorPoint.x) > abs(vectorPoint.y)) then
    begin
      directions[1] := 4;
      directions[2] := 1;
      directions[3] := 3;
      directions[4] := 2;
    end
    else
    begin
      directions[1] := 1;
      directions[2] := 2;
      directions[3] := 3;
      directions[4] := 4;
    end;
    exit;
  end;
  if ((vectorPoint.x < 0) and (vectorPoint.y > 0)) then
  begin
    if (abs(vectorPoint.x) > abs(vectorPoint.y)) then
    begin
      directions[1] := 4;
      directions[2] := 3;
      directions[3] := 1;
      directions[4] := 2;
    end
    else
    begin
      directions[1] := 3;
      directions[2] := 4;
      directions[3] := 2;
      directions[4] := 1;
    end;
    exit;
  end;
  if ((vectorPoint.x > 0) and (vectorPoint.y < 0)) then
  begin
    if (abs(vectorPoint.x) > abs(vectorPoint.y)) then
    begin
      directions[1] := 2;
      directions[2] := 1;
      directions[3] := 3;
      directions[4] := 4;
    end
    else
    begin
      directions[1] := 1;
      directions[2] := 2;
      directions[3] := 4;
      directions[4] := 3;
    end;
    exit;
  end;
  if ((abs(vectorPoint.x) > 0) and (vectorPoint.y = 0)) then
  begin
    if ((vectorPoint.x) > 0) then
    begin
      directions[1] := 2;
      directions[2] := 3;
      directions[3] := 4;
      directions[4] := 1;
    end
    else
    begin
      directions[1] := 3;
      directions[2] := 4;
      directions[3] := 1;
      directions[4] := 2;
    end;
    exit;
  end;
  if (vectorPoint.x = 0) and (abs(vectorPoint.y) > 0) then
  begin
    if ((vectorPoint.y) > 0) then
    begin
      directions[1] := 3;
      directions[2] := 4;
      directions[3] := 1;
      directions[4] := 2;
    end
    else
    begin
      directions[1] := 1;
      directions[2] := 2;
      directions[3] := 3;
      directions[4] := 4;
    end;
    exit;
  end;
end;

procedure TmainForm.recursiveSearch(playerPosition: TPoint; step: integer;
  positions: array of TPoint);
var
  direction, i, lastSimilar: integer;
  newPosition, offsetPoint: TPoint;
  currentPositions: array of TPoint;
  beenThis: boolean;
begin
  // Начало вывода информации
  if (previewCheckBox.Checked and not stopRecursion) then
    fieldDrawGrid.Repaint;
  lastSimilar := 0;
  for i := 0 to Length(pathPositions) - 1 do
  begin
    if ((i <= Length(pathFastest)) and (Length(pathFastest) <> 0)) then
    begin
      if ((pathPositions[i].X = pathFastest[i].X) and
        (pathPositions[i].Y = pathFastest[i].Y)) then
        lastSimilar := lastSimilar + 1;
    end;
  end;
  if ((fastestStepsCount > 0) and (fastestStepsCount < step + 1)) then
    Exit;
  if (lastSimilar <> -1) then
    similarLabeledEdit.Text := IntToStr(lastSimilar);
  currentLabeledEdit.Text := IntToStr(step);
  if (fastestStepsCount <> -1) then
    fastestLabeledEdit.Text := IntToStr(fastestStepsCount)
  else
    fastestLabeledEdit.Text := 'Не вычислен';
  stepsCount := stepsCount + 1;
  stepsLabeledEdit.Text := IntToStr(stepsCount);
  Application.ProcessMessages;
  // Конец вывода информации
  direction := 0;
  if (not stopRecursion) then
  begin
    while direction < 4 do
    begin
      beenThis := False;
      direction := direction + 1;
      SetLength(currentPositions, Length(positions) + 1);
      SetLength(pathPositions, Length(positions));
      for i := 0 to Length(positions) - 1 do
      begin
        currentPositions[i].X := positions[i].X;
        currentPositions[i].Y := positions[i].Y;
        pathPositions[i].X := positions[i].X;
        pathPositions[i].Y := positions[i].Y;
      end;
      case directions[direction] of
        1:
        begin
          offsetPoint := Point(0, -1);
          if ((playerPosition.Y - 1) <= 0) then
            continue;
        end;
        2:
        begin
          offsetPoint := Point(1, 0);
          if ((playerPosition.X + 1) > 20) then
            continue;
        end;
        3:
        begin
          offsetPoint := Point(0, 1);
          if ((playerPosition.Y + 1) > 20) then
            continue;
        end;
        4:
        begin
          offsetPoint := Point(-1, 0);
          if ((playerPosition.X - 1) <= 0) then
            continue;
        end;
      end;
      newPosition.X := playerPosition.X + offsetPoint.X;
      newPosition.Y := playerPosition.Y + offsetPoint.Y;
      currentScanPosition := newPosition;
      currentPositions[Length(positions)].X := newPosition.X;
      currentPositions[Length(positions)].Y := newPosition.Y;
      for i := 0 to Length(positions) - 1 do  // Узнаем, были ли мы в данной точке
      begin
        beenThis := ((positions[i].X = newPosition.X) and
          (positions[i].Y = newPosition.Y));
        if (beenThis) then
        begin
          break;
        end;
      end;
      if (beenThis) then // Если мы были в данной точке, то пропустить текущую итерацию
        continue;
      if ((map[newPosition.X, newPosition.Y] = 3) and
        ((fastestStepsCount = -1) or (step + 1 < fastestStepsCount - 1))) then
      begin
        fastestStepsCount := step + 1;
        fastestLabeledEdit.Text := IntToStr(fastestStepsCount);
        SetLength(pathFastest, Length(positions));
        for i := 0 to Length(positions) - 1 do
        begin
          pathFastest[i].X := positions[i].X;
          pathFastest[i].Y := positions[i].Y;
        end;
        fieldDrawGrid.Repaint;
        exit;
      end
      else if ((map[newPosition.X, newPosition.Y] = 0) and not beenThis) then
      begin
        if (not PointsEqual(currentScanPosition, Point(0, 0))) then
          setDirectionsWeight(currentScanPosition, gatePosition);
        recursiveSearch(newPosition, step + 1, currentPositions);
      end;
    end;
    if (step = 0) then
    begin
      SetLength(pathPositions, 0);
      fieldDrawGrid.Repaint;
      currentLabeledEdit.Text := 'Путь не вычисляется';
    end;
  end
  else // Код выполняется при выходе из рекурсии
  begin
    fastestStepsCount := -1;
    SetLength(pathPositions, 0);
    currentScanPosition := Point(0, 0);
    SetLength(pathFastest, 0);
    Exit;
  end;
end;

procedure TmainForm.stopButtonClick(Sender: TObject);
begin
  stopRecursion := True;
end;

procedure TmainForm.saveButtonClick(Sender: TObject);
var
  i, j: integer;
  mapFile: file of integer;
begin
  if saveDialog.Execute then
  begin
    AssignFile(mapFile, UTF8ToSys(saveDialog.FileName));
    Rewrite(mapFile);
    for i := 1 to 20 do
    begin
      for j := 1 to 20 do
        Write(mapFile, map[i, j]);
    end;
    CloseFile(mapFile);
  end;
end;

procedure TmainForm.loadButtonClick(Sender: TObject);
var
  i, j: integer;
  mapFile: file of integer;
begin
  if loadDialog.Execute then
  begin
    clearButton.Click;
    playerPlaced := False;
    gatePlaced := False;
    AssignFile(mapFile, UTF8ToSys(loadDialog.FileName));
    reset(mapFile);
    for i := 1 to 20 do
    begin
      for j := 1 to 20 do
      begin
        Read(mapFile, map[i, j]);
        if (map[i, j] = 2) then
        begin
          playerPosition := Point(i, j);
          playerPlaced := True;
        end;
        if (map[i, j] = 3) then
        begin
          gatePosition := Point(i, j);
          gatePlaced := True;
        end;
      end;
    end;
    CloseFile(mapFile);
    findButton.Enabled := (playerPlaced and gatePlaced);
    fieldDrawGrid.Repaint;
  end;
end;

end.
