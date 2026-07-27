; ============================================================================
;  Razer Blade Control - Inno Setup installer script
;  Place at: <project root>\installer.iss
;  Normally built via package.ps1 (which passes the /D defines below), but it
;  also compiles standalone if you open it in the Inno Setup IDE.
;  Get Inno Setup (free): https://jrsoftware.org/isdl.php
; ============================================================================

; -- These are supplied by package.ps1; the fallbacks let it compile on its own.
#ifndef MyAppVersion
  #define MyAppVersion "0.0.0"
#endif
#ifndef SrcDir
  #define SrcDir "target\release"
#endif
#ifndef OutputDir
  #define OutputDir "dist"
#endif

; -- Edit these to taste ------------------------------------------------------
#define MyAppName "Razer Blade Control"
#define MyAppPublisher "Pip"
#define MyAppURL "https://github.com/aiaiaioh/razer-control-win"
#define MyAppExeName "razer-gui.exe"
#define MyDaemonExeName "razer-daemon.exe"

[Setup]
; AppId uniquely identifies the app for upgrades/uninstall. KEEP THIS CONSTANT
; across releases (don't regenerate it), or Windows will treat each release as
; a separate program.
AppId={{8B1E7A64-3C29-4D5F-9E17-5A2C6F0B4D91}}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}/issues
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputDir={#OutputDir}
OutputBaseFilename=RazerBladeControl-v{#MyAppVersion}-setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
UninstallDisplayIcon={app}\{#MyAppExeName}
; -- 64-bit only. If you have Inno Setup OLDER than 6.3, change both lines
;    below from "x64" to nothing, or update Inno. On 6.3+ "x64" still works.
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
; -- Optional: give the installer its own icon (point at your .ico):
; SetupIconFile=assets\icon.ico

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Additional shortcuts:"

[Files]
Source: "{#SrcDir}\{#MyAppExeName}";    DestDir: "{app}"; Flags: ignoreversion
Source: "{#SrcDir}\{#MyDaemonExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "README.txt";                   DestDir: "{app}"; Flags: ignoreversion isreadme

[Icons]
Name: "{group}\{#MyAppName}";             Filename: "{app}\{#MyAppExeName}"
Name: "{group}\Uninstall {#MyAppName}";   Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}";       Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Launch {#MyAppName} now"; Flags: nowait postinstall skipifsilent

; Note: autostart-at-logon is handled inside the app itself (System tab ->
; "Run daemon at startup"), so the installer intentionally doesn't touch
; Task Scheduler. User settings live in %APPDATA%\razercontrol and are left in
; place on uninstall.
