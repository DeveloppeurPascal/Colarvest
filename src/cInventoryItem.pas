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
    ItemCountBackground: TEllipse;
    procedure FrameResize(Sender: TObject);
  private
    FInventoryItem: TInventoryItem;
    procedure SetInventoryItem(const Value: TInventoryItem);
    function GetCountLabel: string;
    procedure SetCountLabel(const Value: string);
    { Déclarations privées }
  public
    { Déclarations publiques }
    property InventoryItem: TInventoryItem read FInventoryItem
      write SetInventoryItem;
    property CountLabel: string read GetCountLabel write SetCountLabel;
    constructor Create(AOwner: TComponent); override;
  end;

implementation

{$R *.fmx}
{ TcadInventoryItem }

constructor TcadInventoryItem.Create(AOwner: TComponent);
begin
  inherited;
  name := ''; // avoid duplicate component name
end;

procedure TcadInventoryItem.FrameResize(Sender: TObject);
begin
  width := 2 * height;
end;

function TcadInventoryItem.GetCountLabel: string;
begin
  result := ItemCount.Text;
end;

procedure TcadInventoryItem.SetCountLabel(const Value: string);
begin
  ItemCount.Text := Value;
end;

procedure TcadInventoryItem.SetInventoryItem(const Value: TInventoryItem);
begin
  if assigned(Value) or (FInventoryItem.Count < 1) then
  begin
    FInventoryItem := Value;
    Background.Fill.Color := FInventoryItem.Color;
    CountLabel := FInventoryItem.Count.ToString;
    // TODO : add event to link inventory item and its display
  end
  else
    tthread.forcequeue(nil,
      procedure
      begin
        Self.Free;
        // If no inventory item attached, then kill Self next program loop
      end);
end;

end.
