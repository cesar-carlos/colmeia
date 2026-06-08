; Colmeia - Inno Setup script
; Version is synchronized by installer/update_version.py

#define MyAppName "Colmeia"
#define MyAppVersion "1.4.0"
#define MyAppPublisher "Se7e Sistemas"
#define MyAppURL "https://github.com/cesar-carlos/colmeia"
#define MyAppExeName "colmeia.exe"

[Setup]
AppId={{F66BF94F-F6BA-49D0-8043-1425CEA7E3FD}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
OutputDir=dist
OutputBaseFilename=Colmeia-Setup-{#MyAppVersion}
SetupIconFile=setup_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
Compression=lzma
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
ArchitecturesInstallIn64BitMode=x64compatible
ArchitecturesAllowed=x64compatible
MinVersion=10.0
CloseApplications=yes
CloseApplicationsFilter=colmeia.exe
SetupLogging=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "brazilianportuguese"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Excludes: "*.pdb,*.ilk,*.exp,*.lib,*.log"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\Desinstalar {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Code]
function IsVCRedistInstalled(): Boolean;
var
  Installed: Cardinal;
begin
  if RegQueryDWordValue(
    HKLM64,
    'SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64',
    'Installed',
    Installed
  ) then
    Result := Installed = 1
  else
    Result := False;
end;

function InitializeSetup(): Boolean;
begin
  Result := True;

  if not IsVCRedistInstalled() then
  begin
    if WizardSilent() then
    begin
      Log('Microsoft Visual C++ Redistributable x64 was not detected. Continuing because setup is running silently.');
    end
    else
    begin
      if MsgBox('Microsoft Visual C++ Redistributable x64 nao foi detectado.' + #13#10 + #13#10 +
        'Instale-o antes de usar o ' + ExpandConstant('{#MyAppName}') + ':' + #13#10 +
        'https://aka.ms/vs/17/release/vc_redist.x64.exe' + #13#10 + #13#10 +
        'Deseja continuar a instalacao mesmo assim?', mbConfirmation, MB_YESNO) = IDNO then
        Result := False;
    end;
  end;
end;
