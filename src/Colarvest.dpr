program Colarvest;

uses
  System.StartUpCopy,
  FMX.Forms,
  fMain in 'fMain.pas' {frmMain},
  cButton in 'cButton.pas' {cadButton: TFrame},
  FMX.DzHTMLText in '..\Libraries\DzHTMLText\FMX.DzHTMLText.pas',
  uGameData in 'uGameData.pas',
  cInventoryItem in 'cInventoryItem.pas' {cadInventoryItem: TFrame},
  udmLDJam52_Icones_AS303523361 in 'udmLDJam52_Icones_AS303523361.pas' {dmLDJam52_Icones_AS303523361: TDataModule};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.CreateForm(TdmLDJam52_Icones_AS303523361, dmLDJam52_Icones_AS303523361);
  Application.Run;
end.
