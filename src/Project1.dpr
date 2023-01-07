program Project1;

uses
  System.StartUpCopy,
  FMX.Forms,
  fMain in 'fMain.pas' {frmMain},
  cButton in 'cButton.pas' {cadButton: TFrame},
  FMX.DzHTMLText in '..\Libraries\DzHTMLText\FMX.DzHTMLText.pas',
  uGameData in 'uGameData.pas',
  cInventoryItem in 'cInventoryItem.pas' {cadInventoryItem: TFrame};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
