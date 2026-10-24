; The setup.exe installer, built by tool/package/windows.ps1 with
;   ISCC /DAppVersion=0.3.0 /DBundleDir=<release folder> /DOutputDir=<dist> stash.iss
; It installs for the current user without asking for admin rights, or for
; everyone if the user picks that.

#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif

[Setup]
AppId={{BD09A31D-2D32-49A6-AC87-ABAB242E7132}
AppName=Stash
AppVersion={#AppVersion}
AppPublisher=SalehTZ
AppPublisherURL=https://github.com/SalehTZ/Stash
AppSupportURL=https://github.com/SalehTZ/Stash/issues
DefaultDirName={autopf}\Stash
DefaultGroupName=Stash
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir={#OutputDir}
OutputBaseFilename=stash-windows-x64-setup
SetupIconFile=..\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\stash.exe
Compression=lzma2
SolidCompression=yes
WizardStyle=modern

[Tasks]
Name: desktopicon; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#BundleDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\Stash"; Filename: "{app}\stash.exe"
Name: "{autodesktop}\Stash"; Filename: "{app}\stash.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\stash.exe"; Description: "{cm:LaunchProgram,Stash}"; Flags: nowait postinstall skipifsilent
