unit cButton;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Objects;

type
  TcadButton = class(TFrame)
    Background: TRectangle;
    Text: TText;
  private
    { Déclarations privées }
  public
    { Déclarations publiques }
    procedure DisableButton;
    procedure EnableButton;
    constructor Create(AOwner: TComponent); override;
  end;

implementation

{$R *.fmx}
{ TcadButton }

constructor TcadButton.Create(AOwner: TComponent);
begin
  inherited;
  EnableButton;
end;

procedure TcadButton.DisableButton;
begin
  hittest := false;
  enabled := false;
  opacity := 0.5;
end;

procedure TcadButton.EnableButton;
begin
  hittest := true;
  enabled := true;
  opacity := 1;
end;

end.
