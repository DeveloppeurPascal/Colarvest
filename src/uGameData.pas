unit uGameData;

interface

uses
  System.Classes, System.Generics.Collections, System.UITypes;

Const
  CNbItemByDefaut = 6; // Default items in inventory
  CItemCountByDefault = 10; // Default number of each item in inventory
  CGameGridWidth = 100;
  CGameGridHeight = 100;

  CGridColor = $FFA37929;
  CDeadCellColor = $FFAA9E88;
  CCompostCellColor = $FFF5E475;

type
{$SCOPEDENUMS ON}
  TGameItemState = (Nothing = -1, Planted = 0, Mature = 30, Rotten = 50,
    Dead = 60, Compost = 120, Disable = 180);
  TGameItemColor = TAlphaColor; // ARVB colors (alpha, red, green, blue)

  TGameItem = class
  private
    FState: TGameItemState;
    FColor: TGameItemColor;
    FDuration: integer;
    FX: integer;
    FY: integer;
    FOnStateChange: TNotifyEvent;
    FOnColorChange: TNotifyEvent;
    FStartColor: TGameItemColor;
    procedure SetColor(const Value: TGameItemColor);
    procedure SetDuration(const Value: integer);
    procedure SetState(const Value: TGameItemState);
    procedure SetX(const Value: integer);
    procedure SetY(const Value: integer);
    procedure SetOnStateChange(const Value: TNotifyEvent);
    procedure SetOnColorChange(const Value: TNotifyEvent);
  public
    property State: TGameItemState read FState write SetState;
    property OnStateChange: TNotifyEvent read FOnStateChange
      write SetOnStateChange;
    property Color: TGameItemColor read FColor write SetColor;
    property StartColor: TGameItemColor read FStartColor;
    property OnColorChange: TNotifyEvent read FOnColorChange
      write SetOnColorChange;
    property Duration: integer read FDuration write SetDuration;
    property X: integer read FX write SetX;
    property Y: integer read FY write SetY;
    procedure SaveToStream(AStream: TStream); virtual;
    procedure LoadFromStream(AStrem: TStream); virtual;
    procedure ExecGameLoop;
    constructor Create; overload; Virtual;
    constructor Create(AX, AY: integer); overload; Virtual;
  end;

  TRowList = TObjectDictionary<integer, TGameItem>;
  TColList = TObjectDictionary<integer, TRowList>;

  TGameGrid = class
  private
    FGrid: TColList;
  public
    procedure SetItem(X, Y: integer; Item: TGameItem);
    function GetItem(X, Y: integer): TGameItem;
    procedure RemoveItem(X, Y: integer);
    procedure SaveToStream(AStream: TStream);
    procedure LoadFromStream(AStrem: TStream);
    procedure Clear;
    constructor Create; virtual;
    destructor Destroy; override;
    procedure ExecGameLoop;
  end;

  TInventory = class;

  TInventoryItem = class(TGameItem)
  private
    FCount: integer;
    FOnCountChange: TNotifyEvent;
    procedure SetCount(const Value: integer);
    procedure SetOnCountChange(const Value: TNotifyEvent);
  protected
    Parent: TInventory;
  public
    property Count: integer read FCount write SetCount;
    property OnCountChange: TNotifyEvent read FOnCountChange
      write SetOnCountChange;
    constructor Create(Inventory: TInventory); overload; virtual;
    destructor Destroy; override;
    procedure SaveToStream(AStream: TStream); override;
    procedure LoadFromStream(AStrem: TStream); override;
  end;

  TInventoryItemList = TList<TInventoryItem>;

  TInventory = class
  private
    Items: TInventoryItemList;
    function GetCount: integer;
  public
    property Count: integer read GetCount;
    function Add(Item: TInventoryItem): integer;
    function Get(Index: integer): TInventoryItem; overload;
    function Get(Color: TGameItemColor): TInventoryItem; overload;
    procedure Remove(Item: TInventoryItem); overload;
    procedure SaveToStream(AStream: TStream);
    procedure LoadFromStream(AStrem: TStream);
    procedure Clear;
    constructor Create; virtual;
    destructor Destroy; override;
  end;

  TGameData = class
  private
    FInventory: TInventory;
    FGameGrid: TGameGrid;
    procedure SetGameGrid(const Value: TGameGrid);
    procedure SetInventory(const Value: TInventory);
  public
    property GameGrid: TGameGrid read FGameGrid write SetGameGrid;
    property Inventory: TInventory read FInventory write SetInventory;
    procedure Clear;
    procedure NewGame;
    procedure SaveToFile(AFileName: string);
    procedure LoadFromFile(AFileName: string);
    procedure SaveToStream(AStream: TStream);
    procedure LoadFromStream(AStrem: TStream);
    class function Current: TGameData;
    constructor Create; virtual;
    destructor Destroy; override;
    procedure ExecGameLoop;
  end;

implementation

uses
  System.SysUtils;

var
  GameData: TGameData;

  { TGameData }

constructor TGameData.Create;
begin
  FGameGrid := nil;
  FInventory := nil;
end;

class function TGameData.Current: TGameData;
begin
  if not assigned(GameData) then
  begin
    GameData := TGameData.Create;
    GameData.Clear;
  end;
  result := GameData;
end;

destructor TGameData.Destroy;
begin
  FGameGrid.Free;
  FInventory.Free;
  inherited;
end;

procedure TGameData.ExecGameLoop;
begin
  GameGrid.ExecGameLoop;
end;

procedure TGameData.Clear;
begin
  if not assigned(FGameGrid) then
    FGameGrid := TGameGrid.Create;
  FGameGrid.Clear;

  if not assigned(FInventory) then
    FInventory := TInventory.Create;
  FInventory.Clear;
end;

procedure TGameData.LoadFromFile(AFileName: string);
var
  fs: tfilestream;
begin
  // TODO : check if file exists
  GameData.Clear;
  fs := tfilestream.Create(AFileName, fmInput); // TODO : check "fmInput"
  try
    LoadFromStream(fs);
  finally
    fs.Free;
  end;
end;

procedure TGameData.LoadFromStream(AStrem: TStream);
begin
  // TODO : à compléter
end;

procedure TGameData.NewGame;
var
  Item: TInventoryItem;
begin
  Clear;

  // init Inventory with default values
  for var i := 0 to CNbItemByDefaut - 1 do
  begin
    Item := TInventoryItem.Create(Inventory);
    Item.Count := CItemCountByDefault;
    case i of
      5:
        Item.Color := talphacolorrec.Red;
      4:
        Item.Color := talphacolorrec.orange;
      3:
        Item.Color := talphacolorrec.yellow;
      2:
        Item.Color := talphacolorrec.green;
      1:
        Item.Color := talphacolorrec.darkblue;
      0:
        Item.Color := talphacolorrec.Darkviolet;
    else
      raise exception.Create('No default color available !');
    end;
  end;
end;

procedure TGameData.SaveToFile(AFileName: string);
var
  fs: tfilestream;
begin
  // TODO : check if file exists
  fs := tfilestream.Create(AFileName, fmcreate); // TODO : check "fmCreate"
  try
    SaveToStream(fs);
  finally
    fs.Free;
  end;
end;

procedure TGameData.SaveToStream(AStream: TStream);
begin
  // TODO : à compléter
end;

procedure TGameData.SetGameGrid(const Value: TGameGrid);
begin
  FGameGrid := Value;
end;

procedure TGameData.SetInventory(const Value: TInventory);
begin
  FInventory := Value;
end;

{ TGameItem }

constructor TGameItem.Create;
begin
  FState := TGameItemState.Nothing;
  FColor := 0;
  FStartColor := 0;
  FDuration := 0;
  FX := -1;
  FY := -1;
end;

constructor TGameItem.Create(AX, AY: integer);
begin
  Create;
  X := AX;
  Y := AY;
end;

procedure TGameItem.ExecGameLoop;

  procedure Contamination(X, Y: integer);
  var
    Item: TGameItem;
  begin
    Item := TGameData.Current.GameGrid.GetItem(X, Y);
    if assigned(Item) and (Item.Duration < ord(TGameItemState.Rotten)) then
      Item.Duration := ord(TGameItemState.Rotten);
  end;

var
  colrec: talphacolorrec;
begin
  Duration := Duration + 1;

  if Duration > ord(TGameItemState.Disable) then
    // TODO : kill my self
  else if Duration >= ord(TGameItemState.Compost) then
  begin
    State := TGameItemState.Compost;
    Color := CCompostCellColor;
  end
  else if Duration >= ord(TGameItemState.Dead) then
  begin
    State := TGameItemState.Dead;
    Color := CDeadCellColor;

    // contamination
    Contamination(X - 1, Y - 1);
    Contamination(X - 1, Y);
    Contamination(X - 1, Y + 1);
    Contamination(X, Y - 1);
    Contamination(X, Y + 1);
    Contamination(X + 1, Y - 1);
    Contamination(X + 1, Y);
    Contamination(X + 1, Y + 1);
  end
  else if Duration >= ord(TGameItemState.Rotten) then
    State := TGameItemState.Rotten
  else if Duration >= ord(TGameItemState.Mature) then
    State := TGameItemState.Mature;

  case State of
    TGameItemState.Planted:
      begin
        colrec := talphacolorrec.Create(Color);
        if (colrec.R <= 255 - 3) then
          colrec.R := colrec.R + 3;
        if (colrec.g <= 255 - 3) then
          colrec.g := colrec.g + 3;
        if (colrec.b <= 255 - 3) then
          colrec.b := colrec.b + 3;
        Color := colrec.Color;
      end;
    TGameItemState.Rotten, TGameItemState.Mature:
      begin
        colrec := talphacolorrec.Create(Color);
        if (colrec.R > 3) then
          colrec.R := colrec.R - 3;
        if (colrec.g > 3) then
          colrec.g := colrec.g - 3;
        if (colrec.b > 3) then
          colrec.b := colrec.b - 3;
        Color := colrec.Color;
      end;
  end;
end;

procedure TGameItem.LoadFromStream(AStrem: TStream);
begin
  // TODO : à compléter
end;

procedure TGameItem.SaveToStream(AStream: TStream);
begin
  // TODO : à compléter
end;

procedure TGameItem.SetColor(const Value: TGameItemColor);
begin
  if (FColor <> Value) then
  begin
    if FStartColor = 0 then
      FStartColor := Value;
    FColor := Value;
    if assigned(OnColorChange) then
      OnColorChange(Self);
  end;
end;

procedure TGameItem.SetDuration(const Value: integer);
begin
  FDuration := Value;
end;

procedure TGameItem.SetOnColorChange(const Value: TNotifyEvent);
begin
  FOnColorChange := Value;
end;

procedure TGameItem.SetOnStateChange(const Value: TNotifyEvent);
begin
  FOnStateChange := Value;
end;

procedure TGameItem.SetState(const Value: TGameItemState);
begin
  if (FState <> Value) then
  begin
    FState := Value;
    if assigned(OnStateChange) then
      OnStateChange(Self);
  end;
end;

procedure TGameItem.SetX(const Value: integer);
begin
  if (Value >= 0) and (Value < CGameGridWidth) then
    FX := Value
  else
    FX := -1;
end;

procedure TGameItem.SetY(const Value: integer);
begin
  if (Value >= 0) and (Value < CGameGridHeight) then
    FY := Value
  else
    FY := -1;
end;

{ TGameGrid }

procedure TGameGrid.Clear;
begin
  FGrid.Clear;
end;

constructor TGameGrid.Create;
begin
  FGrid := TColList.Create;
end;

destructor TGameGrid.Destroy;
begin
  FGrid.Free;
  inherited;
end;

procedure TGameGrid.ExecGameLoop;
begin
  for var lignes in FGrid.Values do
    for var Item in lignes.Values do
      Item.ExecGameLoop;
end;

function TGameGrid.GetItem(X, Y: integer): TGameItem;
begin
  if assigned(FGrid) and FGrid.containskey(X) and FGrid.Items[X].containskey(Y)
  then
    result := FGrid.Items[X].Items[Y]
  else
    result := nil;
end;

procedure TGameGrid.LoadFromStream(AStrem: TStream);
begin
  // TODO : à compléter
end;

procedure TGameGrid.RemoveItem(X, Y: integer);
begin
  if assigned(GetItem(X, Y)) then
    FGrid.Items[X].Remove(Y);
end;

procedure TGameGrid.SaveToStream(AStream: TStream);
begin
  // TODO : à compléter
end;

procedure TGameGrid.SetItem(X, Y: integer; Item: TGameItem);
begin
  if assigned(FGrid) then
  begin
    if not FGrid.containskey(X) then
      FGrid.Add(X, TRowList.Create);

    FGrid.Items[X].AddOrSetValue(Y, Item);
    Item.X := X;
    Item.Y := Y;
  end;
end;

{ TGameInventory }

function TInventory.Add(Item: TInventoryItem): integer;
begin
  result := Items.Add(Item);
end;

procedure TInventory.Clear;
begin
  while (Items.Count > 0) do
    Items[0].Free;
  // the element remove itself from the list, no delete() to do here
end;

constructor TInventory.Create;
begin
  Items := TInventoryItemList.Create;
end;

destructor TInventory.Destroy;
begin
  Items.Free;
  inherited;
end;

function TInventory.Get(Index: integer): TInventoryItem;
begin
  if (index >= 0) and (index < Items.Count) then
    result := Items[index]
  else
    result := nil;
end;

function TInventory.Get(Color: TGameItemColor): TInventoryItem;
begin
  result := nil;
  if (Items.Count > 0) then
    for var Item in Items do
      if Item.Color = Color then
      begin
        result := Item;
        exit;
      end;
end;

function TInventory.GetCount: integer;
begin
  result := Items.Count;
end;

procedure TInventory.LoadFromStream(AStrem: TStream);
begin
  // TODO : à compléter
end;

procedure TInventory.Remove(Item: TInventoryItem);
begin
  Items.Remove(Item);
end;

procedure TInventory.SaveToStream(AStream: TStream);
begin
  // TODO : à compléter
end;

{ TInventoryItem }

constructor TInventoryItem.Create(Inventory: TInventory);
begin
  inherited Create;
  Parent := Inventory;
  if assigned(Inventory) then
    Inventory.Add(Self);
end;

destructor TInventoryItem.Destroy;
begin
  if assigned(Parent) then
    Parent.Remove(Self);
  inherited;
end;

procedure TInventoryItem.LoadFromStream(AStrem: TStream);
begin
  inherited;
  // TODO : à compléter
end;

procedure TInventoryItem.SaveToStream(AStream: TStream);
begin
  inherited;
  // TODO : à compléter
end;

procedure TInventoryItem.SetCount(const Value: integer);
begin
  FCount := Value;
  if assigned(OnCountChange) then
    OnCountChange(Self);
end;

procedure TInventoryItem.SetOnCountChange(const Value: TNotifyEvent);
begin
  FOnCountChange := Value;
end;

initialization

GameData := nil;
randomize;

finalization

GameData.Free;

end.
