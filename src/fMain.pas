unit fMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts,
  FMX.Objects, FMX.Ani, FMX.StdCtrls, FMX.Controls.Presentation, cButton,
  FMX.DzHTMLText;

Const
  CDefaultMarginsTop = 5;

type
{$SCOPEDENUMS ON}
  TGameScreen = (Home, Credit, Options, Game);

  TfrmMain = class(TForm)
    ScreenHome: TLayout;
    ScreenGame: TLayout;
    ScreenCredit: TLayout;
    ScreenSettings: TLayout;
    Background: TLayout;
    Rectangle1: TRectangle;
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
  private
    { Déclarations privées }
    DisplayedScreen: TLayout;
  public
    { Déclarations publiques }
    procedure DisplayScreen(ScreenToDisplay: TGameScreen);
    procedure DisplayGameTitle(Visible: boolean);
    procedure InitGameText;
    procedure InitCreditScreen;
    procedure InitSettingsScreen;
    procedure CalcScreenHomeMenuHeight;
    procedure PauseGame;
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.fmx}

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
  // TODO : continue prevous game (after a pause)
  DisplayScreen(TGameScreen.Game);
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
  // TODO : initialiser une nouvelle partie
  DisplayScreen(TGameScreen.Game);
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
    TGameScreen.Game:
      NewScreen := ScreenGame;
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

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  // Hide all screens
  for var i := 0 to ChildrenCount - 1 do
    if (Children[i] is TLayout) then
      (Children[i] as TLayout).Visible := false;

  DisplayedScreen := nil;

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
      PauseGame;
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

procedure TfrmMain.InitCreditScreen;
begin
  ScreenCreditContent.margins.top := GameTitle.Position.Y + GameTitle.Height +
    GameTitle.margins.top + GameTitle.margins.bottom + CDefaultMarginsTop;
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

  ScreenCreditText.BeginUpdate;
  try
    ScreenCreditText.Text := '<b>' + GameTitleText.Text + '</b><br>' +
      '(c) Patrick Prémartin 2023<br>' + '<br>' +
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
  // TODO : do what is needed when teh game is stopped

  DisplayScreen(TGameScreen.Home);
end;

end.
