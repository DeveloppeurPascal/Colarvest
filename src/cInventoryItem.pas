unit cInventoryItem;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Objects, uGameData, FMX.Effects;

type
  TcadInventoryItem = class(TFrame)
    Background: TRectangle;
    ItemCount: TText;
    procedure FrameResize(Sender: TObject);
    procedure FrameClick(Sender: TObject);
  private
    FInventoryItem: TInventoryItem;
    FActive: boolean;
    FOnSelectInventoryItem: tnotifyevent;
    FOnUnSelectInventoryItem: tnotifyevent;
    procedure SetInventoryItem(const Value: TInventoryItem);
    procedure SetActive(const Value: boolean);
    procedure SetCount(const Value: integer);
    function GetCount: integer;
    { Déclarations privées }
    procedure KillMySelf;
    function GetColor: TGameItemColor;
    procedure SetOnSelectInventoryItem(const Value: tnotifyevent);
    procedure SetOnUnSelectInventoryItem(const Value: tnotifyevent);
    procedure ItemCountChange(Sender: TObject);
  public
    { Déclarations publiques }
    property InventoryItem: TInventoryItem read FInventoryItem
      write SetInventoryItem;
    property Count: integer read GetCount write SetCount;
    property Color: TGameItemColor read GetColor;
    property Active: boolean read FActive write SetActive;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property OnSelectInventoryItem: tnotifyevent read FOnSelectInventoryItem
      write SetOnSelectInventoryItem;
    property OnUnSelectInventoryItem: tnotifyevent read FOnUnSelectInventoryItem
      write SetOnUnSelectInventoryItem;
    function GetGameItem: tgameitem;
  end;

implementation

{$R *.fmx}
{ TcadInventoryItem }

constructor TcadInventoryItem.Create(AOwner: TComponent);
begin
  inherited;
  name := ''; // avoid duplicate component name
  FInventoryItem := nil;
  Active := false;
end;

destructor TcadInventoryItem.Destroy;
begin
  FInventoryItem.Free;
  inherited;
end;

procedure TcadInventoryItem.FrameClick(Sender: TObject);
begin
  Active := not Active;

  if Active then
    for var i := 0 to parent.ChildrenCount - 1 do
      if (parent.Children[i] is TcadInventoryItem) and
        (parent.Children[i] <> self) then
        (parent.Children[i] as TcadInventoryItem).Active := false;
end;

procedure TcadInventoryItem.FrameResize(Sender: TObject);
begin
  width := 2 * height;
end;

function TcadInventoryItem.GetColor: TGameItemColor;
begin
  if assigned(FInventoryItem) then
    result := FInventoryItem.Color
  else
    result := 0; // transparent color
end;

function TcadInventoryItem.GetCount: integer;
begin
  if assigned(FInventoryItem) then
    result := FInventoryItem.Count
  else
    result := 0;
end;

function TcadInventoryItem.GetGameItem: tgameitem;
begin
  result := tgameitem.Create;
  result.State := TGameItemState.planted;
  if assigned(FInventoryItem) then
    result.Color := FInventoryItem.Color
  else
    result.Color := 0; // transparent color
  result.Duration := 0;
end;

procedure TcadInventoryItem.ItemCountChange(Sender: TObject);
begin
  if assigned(FInventoryItem) then
    ItemCount.Text := FInventoryItem.Count.ToString;
end;

procedure TcadInventoryItem.KillMySelf;
begin
  Active := false;
  tthread.forcequeue(nil,
    procedure
    begin
      self.Free;
      // If no inventory item attached, then kill Self next program loop
    end);
end;

procedure TcadInventoryItem.SetActive(const Value: boolean);
begin
  if Value then
  begin
    Background.Stroke.Color := talphacolors.green;
    Background.Stroke.Thickness := 3;
  end
  else
  begin
    Background.Stroke.Color := talphacolors.black;
    Background.Stroke.Thickness := 1;
  end;

  if (FActive <> Value) then
  begin
    FActive := Value;
    if FActive then
    begin
      if assigned(OnSelectInventoryItem) then
        OnSelectInventoryItem(self);
    end
    else if assigned(OnUnSelectInventoryItem) then
      OnUnSelectInventoryItem(self);
  end;
end;

procedure TcadInventoryItem.SetCount(const Value: integer);
begin
  if (Value < 1) then
    KillMySelf
  else if assigned(FInventoryItem) then
    FInventoryItem.Count := Value;
end;

procedure TcadInventoryItem.SetInventoryItem(const Value: TInventoryItem);
begin
  if assigned(Value) and (Value.Count > 0) then
  begin
    FInventoryItem := Value;
    Background.Fill.Color := FInventoryItem.Color;
    ItemCount.Text := FInventoryItem.Count.ToString;
    FInventoryItem.OnCountChange := ItemCountChange;
  end
  else // TODO: potential memory lost if value assigned with count=0
    KillMySelf;
end;

procedure TcadInventoryItem.SetOnSelectInventoryItem(const Value: tnotifyevent);
begin
  FOnSelectInventoryItem := Value;
end;

procedure TcadInventoryItem.SetOnUnSelectInventoryItem
  (const Value: tnotifyevent);
begin
  FOnUnSelectInventoryItem := Value;
end;

end.
