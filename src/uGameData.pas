unit uGameData;

interface

uses
  System.Classes, System.Generics.Collections, System.UITypes;

Const
  CNbItemByDefaut = 5;
  CItemCountByDefault = 10;
  CGameGridWidth = 100;
  CGameGridHeight = 100;

type
{$SCOPEDENUMS ON}
  TGameItemState = (first, medium, last, dead); // TODO : à changer
  TGameItemColor = TAlphaColor; // RVBA colors

  TGameItem = class
  private
    FState: TGameItemState;
    FColor: TGameItemColor;
    FDuration: integer;
    procedure SetColor(const Value: TGameItemColor);
    procedure SetDuration(const Value: integer);
    procedure SetState(const Value: TGameItemState);
  public
    property State: TGameItemState read FState write SetState;
    property Color: TGameItemColor read FColor write SetColor;
    property Duration: integer read FDuration write SetDuration;
    procedure SaveToStream(AStream: TStream); virtual;
    procedure LoadFromStream(AStrem: TStream); virtual;
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
  end;

  TInventory = class;

  TInventoryItem = class(TGameItem)
  private
    FCount: integer;
    procedure SetCount(const Value: integer);
  protected
    Parent: TInventory;
  public
    property Count: integer read FCount write SetCount;
    constructor Create(Inventory: TInventory); virtual;
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
    function Get(Index: integer): TInventoryItem;
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
  end;

implementation

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
  for var i := 1 to CNbItemByDefaut do
  begin
    Item := TInventoryItem.Create(Inventory);
    Item.Count := CItemCountByDefault;
    Item.Color := TAlphaColorRec.Alpha or
      TAlphaColor((random(256) { R } * 256 + random(256) { V } ) * 256 +
      random(256) { B } );
    // TODO : change the color by default
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
  FColor := Value;
end;

procedure TGameItem.SetDuration(const Value: integer);
begin
  FDuration := Value;
end;

procedure TGameItem.SetState(const Value: TGameItemState);
begin
  FState := Value;
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
    Items[0].Free; // the element remove itself from the list, no delete() to do here
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
  Parent := Inventory;
  if assigned(Inventory) then
    Inventory.Add(self);
end;

destructor TInventoryItem.Destroy;
begin
  if assigned(Parent) then
    Parent.Remove(self);
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
  // TODO : à compléter
end;

initialization

GameData := nil;
randomize;

finalization

GameData.Free;

end.
