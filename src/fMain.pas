unit fMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts,
  FMX.Objects, FMX.Ani, FMX.StdCtrls, FMX.Controls.Presentation, cButton,
  FMX.DzHTMLText, cInventoryItem, uGameData;

Const
  CDefaultMarginsTop = 5;
  // top margin of content text on screens with Title visible
  CGameCellSize = 50; // Widht/Height of a drawn cell on the game grid

type
{$SCOPEDENUMS ON}
  TGameScreen = (Home, Credit, Options, GameStart, GameContinue);

  TfrmMain = class(TForm)
    ScreenHome: TLayout;
    ScreenGame: TLayout;
    ScreenCredit: TLayout;
    ScreenSettings: TLayout;
    Background: TLayout;
    BackgroundImage: TRectangle;
    animHideScreen: TFloatAnimation;
    animShowScreen: TFloatAnimation;
    GameTitle: TLayout;
    GameTitleText: TLabel;
    ScreenHomeMenu: TLayout;
    btnMenuExit: TcadButton;
    btnMenuCredits: TcadButton;
    btnMenuOptions: TcadButton;
    btnMenuContinue: TcadButton;
    btnMenuPlay: TcadButton;
    btnBackFromCredits: TcadButton;
    btnBackFromSettings: TcadButton;
    ScreenCreditContent: TVertScrollBox;
    ScreenCreditText: TDzHTMLText;
    ScreenSettingsContent: TVertScrollBox;
    PlayerInventoryBackground: TRectangle;
    btnPauseGame: TRectangle;
    btnPauseGameSVG: TPath;
    GameGrid: TImage;
    GameLoop: TTimer;
    PlayerInventory: THorzScrollBox;
    procedure FormCreate(Sender: TObject);
    procedure animHideScreenFinish(Sender: TObject);
    procedure animShowScreenFinish(Sender: TObject);
    procedure btnMenuExitClick(Sender: TObject);
    procedure btnMenuContinueClick(Sender: TObject);
    procedure btnMenuPlayClick(Sender: TObject);
    procedure btnMenuOptionsClick(Sender: TObject);
    procedure btnMenuCreditsClick(Sender: TObject);
    procedure btnBackClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char;
      Shift: TShiftState);
    procedure btnPauseGameClick(Sender: TObject);
    procedure GameGridResize(Sender: TObject);
    procedure GameGridTap(Sender: TObject; const Point: TPointF);
    procedure GameGridMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure GameLoopTimer(Sender: TObject);
  private
    { Déclarations privées }
    DisplayedScreen: TLayout;
    GridViewportX, GridViewportY: integer;
    GameStarted: boolean;
    SelectedInventoryItem: TcadInventoryItem;
    procedure SelectInventoryItem(Sender: TObject);
    procedure UnSelectInventoryItem(Sender: TObject);
    procedure ClickOnGameGrid(X, Y: Single);
    procedure GameItemStateChanged(Sender: TObject);
    procedure GameItemColorChanged(Sender: TObject);
  public
    { Déclarations publiques }
    procedure DisplayScreen(ScreenToDisplay: TGameScreen);
    procedure DisplayGameTitle(Visible: boolean);
    procedure InitGameText;
    procedure InitCreditScreen;
    procedure InitSettingsScreen;
    procedure CalcScreenHomeMenuHeight;
    procedure PauseGame;
    procedure InitGameStart(ContinuePreviousGame: boolean = false);
    procedure RefreshGameGrid;
    procedure DrawGameItem(item: tgameitem);
    procedure DrawGameCell(col, lig: integer);
    procedure DrawCell(X, Y: Single; Canvas: TCanvas; item: tgameitem);
    procedure AddInventoryItemButton(InventoryItem: TInventoryItem);
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.fmx}

uses udmLDJam52_Icones_AS303523361;

procedure TfrmMain.AddInventoryItemButton(InventoryItem: TInventoryItem);
var
  InventoryItemBox: TcadInventoryItem;
begin
  InventoryItemBox := TcadInventoryItem.Create(Self);
  InventoryItemBox.Parent := PlayerInventory;
  InventoryItemBox.OnSelectInventoryItem := SelectInventoryItem;
  InventoryItemBox.OnunSelectInventoryItem := UnSelectInventoryItem;
  InventoryItemBox.InventoryItem := InventoryItem;
end;

procedure TfrmMain.animHideScreenFinish(Sender: TObject);
begin
  animHideScreen.enabled := false;
  Assert(animHideScreen.Parent is TLayout, animHideScreen.Parent.Name +
    ' is not a TLayout.');
  (animHideScreen.Parent as TLayout).Visible := false;
end;

procedure TfrmMain.animShowScreenFinish(Sender: TObject);
begin
  animShowScreen.enabled := false;
  Assert(animShowScreen.Parent is TLayout, animShowScreen.Parent.Name +
    ' is not a TLayout.');
  (animShowScreen.Parent as TLayout).Visible := true;
  (animShowScreen.Parent as TLayout).enabled := true;
end;

procedure TfrmMain.btnBackClick(Sender: TObject);
begin
  DisplayScreen(TGameScreen.Home);
end;

procedure TfrmMain.btnMenuContinueClick(Sender: TObject);
begin
  DisplayScreen(TGameScreen.GameContinue);
end;

procedure TfrmMain.btnMenuCreditsClick(Sender: TObject);
begin
  DisplayScreen(TGameScreen.Credit);
end;

procedure TfrmMain.btnMenuExitClick(Sender: TObject);
begin
  close;
end;

procedure TfrmMain.btnMenuOptionsClick(Sender: TObject);
begin
  DisplayScreen(TGameScreen.Options);
end;

procedure TfrmMain.btnMenuPlayClick(Sender: TObject);
begin
  DisplayScreen(TGameScreen.GameStart);
end;

procedure TfrmMain.btnPauseGameClick(Sender: TObject);
begin
  PauseGame;
end;

procedure TfrmMain.CalcScreenHomeMenuHeight;
begin
  ScreenHomeMenu.BeginUpdate;
  try
    ScreenHomeMenu.Height := 0;
    for var i := 0 to ScreenHomeMenu.ChildrenCount - 1 do
      if (ScreenHomeMenu.Children[i] is TcadButton) then
      begin
        var
        btn := (ScreenHomeMenu.Children[i] as TcadButton);
        if btn.Visible then
          ScreenHomeMenu.Height := ScreenHomeMenu.Height + btn.margins.top +
            btn.Height + btn.margins.bottom;
      end;
  finally
    ScreenHomeMenu.endupdate;
  end;
end;

procedure TfrmMain.ClickOnGameGrid(X, Y: Single);
var
  col, row: integer;
  NbCol, NbRow: integer;
  GameData: tgamedata;
  Grid: TGameGrid;
  item: tgameitem;

  procedure IncreaseInventoryItemCount(Color: TGameItemColor; Value: integer);
  var
    InventoryItem: TInventoryItem;
  begin
    InventoryItem := GameData.Inventory.Get(Color);
    if assigned(InventoryItem) then
      InventoryItem.Count := InventoryItem.Count + Value
    else
    begin
      InventoryItem := TInventoryItem.Create(GameData.Inventory);
      InventoryItem.Count := Value;
      InventoryItem.Color := Color;
      AddInventoryItemButton(InventoryItem);
    end;
  end;

begin
  // Nb displayed col/row
  NbCol := (trunc(GameGrid.Width) div CGameCellSize) + 1;
  NbRow := (trunc(GameGrid.Height) div CGameCellSize) + 1;

  // local coordinates to absolute coordinates
  col := trunc(X / CGameCellSize) + GridViewportX - NbCol div 2;
  row := trunc(Y / CGameCellSize) + GridViewportY - NbRow div 2;

  GameData := tgamedata.Current;
  Grid := GameData.GameGrid;

  item := Grid.GetItem(col, row);
  if assigned(item) then
  begin
    // already something there
    case item.state of
      tgameitemstate.Mature:
        begin
          IncreaseInventoryItemCount(item.startColor, 10);
          Grid.RemoveItem(col, row);
          DrawGameCell(col, row);
        end;
      tgameitemstate.rotten:
        begin
          IncreaseInventoryItemCount(item.startColor, 4);
          Grid.RemoveItem(col, row);
          DrawGameCell(col, row);
        end;
      tgameitemstate.compost:
        begin
          IncreaseInventoryItemCount(item.startColor, 2);
          Grid.RemoveItem(col, row);
          DrawGameCell(col, row);
        end;
    end;
  end
  else if assigned(SelectedInventoryItem) then
  begin
    // color selected => put color on the game grid
    item := SelectedInventoryItem.GetGameItem;
    Grid.SetItem(col, row, item);
    item.onstatechange := GameItemStateChanged;
    item.OnColorChange := GameItemColorChanged;
    SelectedInventoryItem.Count := SelectedInventoryItem.Count - 1;
    DrawGameItem(item);
  end;
end;

procedure TfrmMain.DisplayGameTitle(Visible: boolean);
begin
  GameTitle.Visible := Visible;
  if Visible then
    GameTitle.BringToFront;
end;

procedure TfrmMain.DisplayScreen(ScreenToDisplay: TGameScreen);
var
  NewScreen: TLayout;
begin
  // Show the background if it's not shown
  if not Background.Visible then
  begin
    Background.Visible := true;
    Background.BringToFront;
  end;
  BackgroundImage.Fill.Color := talphacolors.azure;

  case ScreenToDisplay of
    TGameScreen.Home:
      NewScreen := ScreenHome;
    TGameScreen.Credit:
      begin
        tthread.ForceQueue(nil,
          procedure
          begin
            InitCreditScreen;
          end);
        NewScreen := ScreenCredit;
      end;
    TGameScreen.Options:
      begin
        tthread.ForceQueue(nil,
          procedure
          begin
            InitSettingsScreen;
          end);
        NewScreen := ScreenSettings;
      end;
    TGameScreen.GameStart, TGameScreen.GameContinue:
      begin
        tthread.ForceQueue(nil,
          procedure
          begin
            InitGameStart(ScreenToDisplay = TGameScreen.GameContinue);
          end);
        NewScreen := ScreenGame;
      end;
  else
    raise exception.Create('Unknow Screen to display.');
  end;

  // Hide actual diplayed screen
  if assigned(DisplayedScreen) and (DisplayedScreen <> NewScreen) then
  begin
    if animHideScreen.enabled then
      raise exception.Create('An other screen is already hiding.');
    DisplayedScreen.enabled := false;
    animHideScreen.Parent := DisplayedScreen;
    animHideScreen.enabled := true;
  end;

  // Show new screen
  NewScreen.Opacity := 1;
  NewScreen.Visible := true;
  NewScreen.enabled := false;
  NewScreen.BringToFront;
  if animShowScreen.enabled then
    raise exception.Create('An other screen is already showing.');
  animShowScreen.Parent := NewScreen;
  animShowScreen.enabled := true;
  DisplayedScreen := NewScreen;

  // Show/Hide game title on top of the screen
  DisplayGameTitle(ScreenToDisplay in [TGameScreen.Home, TGameScreen.Credit,
    TGameScreen.Options]);
end;

procedure TfrmMain.DrawCell(X, Y: Single; Canvas: TCanvas; item: tgameitem);
var
  w, h: Single;
  bmp: tbitmap;
  s: tsizef;
begin
  w := CGameCellSize;
  h := CGameCellSize;
  if assigned(item) then
  begin
    Canvas.Fill.Color := item.Color;
    Canvas.Fill.Kind := TBrushKind.Solid;
    Canvas.FillRect(trectf.Create(X, Y, X + w, Y + h), 1);
    s := tsizef.Create(2 * w / 3, 2 * h / 3);
    case item.state of
      tgameitemstate.Planted:
        bmp := dmLDJam52_Icones_AS303523361.ImageList.Bitmap(s, 4);
      tgameitemstate.Mature:
        bmp := dmLDJam52_Icones_AS303523361.ImageList.Bitmap(s, 6);
      tgameitemstate.rotten:
        bmp := dmLDJam52_Icones_AS303523361.ImageList.Bitmap(s, 5);
      tgameitemstate.Dead:
        bmp := dmLDJam52_Icones_AS303523361.ImageList.Bitmap(s, 1);
      tgameitemstate.compost:
        bmp := dmLDJam52_Icones_AS303523361.ImageList.Bitmap(s, 2);
    else
      raise exception.Create('No icon for this item state.');
    end;
    Canvas.DrawBitmap(bmp, bmp.boundsf, trectf.Create(X, Y, X + w, Y + h), 1);
    // TODO : add margin to destination
  end
  else
  begin
    Canvas.Fill.Color := cgridcolor;
    // TODO : grid background color
    Canvas.Fill.Kind := TBrushKind.Solid;
    Canvas.FillRect(trectf.Create(X, Y, X + w, Y + h), 1);
  end;
end;

procedure TfrmMain.DrawGameCell(col, lig: integer);
var
  NbCol, NbRow: integer;
  X, Y: Single;
begin
  if not GameStarted then
    exit;

  NbCol := (trunc(GameGrid.Width) div CGameCellSize) + 1;
  NbRow := (trunc(GameGrid.Height) div CGameCellSize) + 1;

  if (col < GridViewportX - NbCol div 2) or (col > GridViewportX + NbCol div 2)
    or (lig < GridViewportY - NbRow div 2) or (lig > GridViewportY + NbRow div 2)
  then
    exit;

  GameGrid.BeginUpdate;
  try
    GameGrid.Bitmap.Canvas.BeginScene;
    try
      // draw the item cell and its picture
      X := (col - GridViewportX + NbCol div 2) * CGameCellSize;
      Y := (lig - GridViewportY + NbRow div 2) * CGameCellSize;
      DrawCell(X, Y, GameGrid.Bitmap.Canvas, nil);
    finally
      GameGrid.Bitmap.Canvas.endscene;
    end;
  finally
    GameGrid.endupdate;
  end;
end;

procedure TfrmMain.DrawGameItem(item: tgameitem);
var
  NbCol, NbRow: integer;
  X, Y: Single;
begin
  if not GameStarted then
    exit;

  if (not assigned(item)) or (item.state = tgameitemstate.nothing) or
    (item.state = tgameitemstate.Disable) then
    exit;

  NbCol := (trunc(GameGrid.Width) div CGameCellSize) + 1;
  NbRow := (trunc(GameGrid.Height) div CGameCellSize) + 1;

  if (item.X < GridViewportX - NbCol div 2) or
    (item.X > GridViewportX + NbCol div 2) or
    (item.Y < GridViewportY - NbRow div 2) or
    (item.Y > GridViewportY + NbRow div 2) then
    exit;

  GameGrid.BeginUpdate;
  try
    GameGrid.Bitmap.Canvas.BeginScene;
    try
      // draw the item cell and its picture
      X := (item.X - GridViewportX + NbCol div 2) * CGameCellSize;
      Y := (item.Y - GridViewportY + NbRow div 2) * CGameCellSize;
      DrawCell(X, Y, GameGrid.Bitmap.Canvas, item);
    finally
      GameGrid.Bitmap.Canvas.endscene;
    end;
  finally
    GameGrid.endupdate;
  end;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  // Hide all screens
  for var i := 0 to ChildrenCount - 1 do
    if (Children[i] is TLayout) then
      (Children[i] as TLayout).Visible := false;

  DisplayedScreen := nil;
  GameStarted := false;

  // Defer Home screen display
  tthread.ForceQueue(nil,
    procedure
    begin
      DisplayScreen(TGameScreen.Home);
    end);

  InitGameText;

  // Disable "Continue" button if no previous game data
  btnMenuContinue.DisableButton;
  // TODO : enable the button if previous game data exists

  // hide Settings button (nothing in the screen for now)
  btnMenuOptions.Visible := false;

{$IF Defined(IOS) or Defined(ANDROID)}
  // remove EXIT button on iOS&Android
  btnMenuExit.enabled := false;
  btnMenuExit.Visible := false;
{$ENDIF}
  CalcScreenHomeMenuHeight;
end;

procedure TfrmMain.FormKeyDown(Sender: TObject; var Key: Word;
var KeyChar: Char; Shift: TShiftState);
begin
  if Key in [vkEscape, vkHardwareBack] then
  begin
    if (DisplayedScreen = ScreenCredit) then
    begin
      Key := 0;
      KeyChar := #0;
      btnBackFromCredits.onclick(Self);
    end
    else if (DisplayedScreen = ScreenSettings) then
    begin
      Key := 0;
      KeyChar := #0;
      btnBackFromSettings.onclick(Self);
    end
    else if (DisplayedScreen = ScreenGame) then
    begin
      Key := 0;
      KeyChar := #0;
      btnPauseGame.onclick(Self);
    end
{$IF Defined(IOS) or Defined(ANDROID)}
    else;
{$ELSE}
    else
    begin
      Key := 0;
      KeyChar := #0;
      btnMenuExit.onclick(Self);
    end;
{$ENDIF}
  end;
end;

procedure TfrmMain.GameGridMouseDown(Sender: TObject; Button: TMouseButton;
Shift: TShiftState; X, Y: Single);
begin
  ClickOnGameGrid(X, Y);
end;

procedure TfrmMain.GameGridResize(Sender: TObject);
begin
  GameGrid.Bitmap.SetSize(trunc(GameGrid.Width * GameGrid.Bitmap.BitmapScale),
    trunc(GameGrid.Height * GameGrid.Bitmap.BitmapScale));
  if (ScreenGame.Visible) then
    RefreshGameGrid;
end;

procedure TfrmMain.GameGridTap(Sender: TObject; const Point: TPointF);
begin
  // ClickOnGameGrid(Point.X, Point.Y);
  // onTap generate a onMouseDown
end;

procedure TfrmMain.GameItemColorChanged(Sender: TObject);
var
  item: tgameitem;
begin
  if not(Sender is tgameitem) then
    exit;
  item := Sender as tgameitem;
  DrawGameItem(item);
end;

procedure TfrmMain.GameItemStateChanged(Sender: TObject);
var
  item: tgameitem;
begin
  if not(Sender is tgameitem) then
    exit;
  item := Sender as tgameitem;
  DrawGameItem(item);
end;

procedure TfrmMain.InitCreditScreen;
begin
  ScreenCreditContent.margins.top := GameTitle.Position.Y + GameTitle.Height +
    GameTitle.margins.top + GameTitle.margins.bottom + CDefaultMarginsTop;
end;

procedure TfrmMain.InitGameStart(ContinuePreviousGame: boolean);
var
  GameData: tgamedata;
  InventoryItemBox: TcadInventoryItem;
begin
  BackgroundImage.Fill.Color := talphacolors.black;

  SelectedInventoryItem := nil;

  // Init the game screen
  while PlayerInventory.content.ChildrenCount > 0 do
    PlayerInventory.content.Children[0].Free;

  // Init or load game data
  GameData := tgamedata.Current;
  if ContinuePreviousGame then
    GameData.LoadFromFile('PreviousGameData')
    // TODO : change game data filename
  else
    GameData.NewGame;

  GameStarted := true;

  for var i := 0 to GameData.Inventory.Count - 1 do
    AddInventoryItemButton(GameData.Inventory.Get(i));

  // The viewport (X,Y) is the center of the screen, not the top/left coordinates
  GridViewportX := CGameGridWidth div 2;
  GridViewportY := CGameGridHeight div 2;

  // Show the game grid
  RefreshGameGrid;

  // Last operation : starting the game loop
  GameLoop.enabled := true;
end;

procedure TfrmMain.InitGameText;
begin
  // TODO : translate texts if needed

  btnMenuPlay.Text.Text := 'Play';
  btnMenuContinue.Text.Text := 'Continue';
  btnMenuOptions.Text.Text := 'Options';
  btnMenuCredits.Text.Text := 'Credits';
  btnMenuExit.Text.Text := 'Exit';
  btnBackFromCredits.Text.Text := 'Home';
  btnBackFromSettings.Text.Text := 'Home';

  GameTitleText.Text := 'Colarvest';

  ScreenCreditText.BeginUpdate;
  try
    ScreenCreditText.Text := '<b>' + GameTitleText.Text + '</b><br>' +
      '(c) Patrick Prémartin 2023<br>' + '<br>' +
      'Some pictures are under license from Google and Adobe Stock.<br>' +
      'Thanks to <a:https://github.com/digao-dalpiaz>Rodrigo Depiné Dalpiaz</a> for his <a:https://github.com/digao-dalpiaz/DzHTMLText>DzHTMLText</a> component.';
  finally
    ScreenCreditText.endupdate;
  end;

  caption := GameTitleText.Text;
end;

procedure TfrmMain.InitSettingsScreen;
begin
  ScreenSettingsContent.margins.top := GameTitle.Position.Y + GameTitle.Height +
    GameTitle.margins.top + GameTitle.margins.bottom + CDefaultMarginsTop;
end;

procedure TfrmMain.PauseGame;
begin
  // TODO : do what is needed when the game is stopped
  GameStarted := false;
  GameLoop.enabled := false;
  DisplayScreen(TGameScreen.Home);
end;

procedure TfrmMain.RefreshGameGrid;
var
  NbCol, NbRow: integer;
  GameData: tgamedata;
  item: tgameitem;
  GridCanvas: TCanvas;
  X, Y: Single;
  i, j: integer;
begin
  if not GameStarted then
    exit;

  GameData := tgamedata.Current;

  NbCol := (trunc(GameGrid.Width) div CGameCellSize) + 1;
  NbRow := (trunc(GameGrid.Height) div CGameCellSize) + 1;

  GameGrid.BeginUpdate;
  try
    GridCanvas := GameGrid.Bitmap.Canvas;
    GridCanvas.BeginScene;
    try
      GridCanvas.Clear(cgridcolor);
      for i := 0 to NbCol - 1 do
        for j := 0 to NbRow - 1 do
        begin
          // Viewport(x,y) is the center, we need the displayed cell on top/left of the screen
          item := GameData.GameGrid.GetItem(GridViewportX + i - NbCol div 2,
            GridViewportY + j - NbRow div 2);

          // draw the item cell and its picture
          if assigned(item) and (item.state <> tgameitemstate.nothing) and
            (item.state <> tgameitemstate.Disable) then
          begin
            X := i * CGameCellSize;
            Y := j * CGameCellSize;
            DrawCell(X, Y, GameGrid.Bitmap.Canvas, item)
          end;
        end;
    finally
      GridCanvas.endscene;
    end;
  finally
    GameGrid.endupdate;
  end;
end;

procedure TfrmMain.SelectInventoryItem(Sender: TObject);
begin
  if (Sender is TcadInventoryItem) then
    SelectedInventoryItem := (Sender as TcadInventoryItem);
end;

procedure TfrmMain.GameLoopTimer(Sender: TObject);
begin
  if not GameStarted then
  begin
    GameLoop.enabled := false;
    exit;
  end;

  tgamedata.Current.ExecGameLoop;
end;

procedure TfrmMain.UnSelectInventoryItem(Sender: TObject);
begin
  if (Sender is TcadInventoryItem) and
    (SelectedInventoryItem = (Sender as TcadInventoryItem)) then
    SelectedInventoryItem := nil;
end;

initialization

{$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := true;
{$ENDIF}

end.
