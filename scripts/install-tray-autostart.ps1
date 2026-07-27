# ============================================
#  Install Tray Icon Auto-Start Shortcut
#  Adds GUI to Windows Startup folder
# ============================================

Write-Host "`n=== Installing Razer-Control-Win Tray Auto-Start ===`n" -ForegroundColor Cyan

# Ensure elevation
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Host "Restarting script with admin privileges..." -ForegroundColor Yellow
    Start-Process powershell "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Locate GUI executable
$RepoRoot = Split-Path $PSScriptRoot -Parent
$GuiExe = Join-Path $RepoRoot "target\release\razer-gui.exe"

if (-not (Test-Path $GuiExe)) {
    Write-Error "GUI executable not found: $GuiExe"
    exit 1
}

Write-Host "Using GUI: $GuiExe" -ForegroundColor Cyan

# Startup folder
$Startup = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
$ShortcutPath = Join-Path $Startup "RazerControlWin.lnk"

# Create WScript Shell COM object
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($ShortcutPath)

$Shortcut.TargetPath = $GuiExe
$Shortcut.WorkingDirectory = Split-Path $GuiExe
$Shortcut.WindowStyle = 7   # Hidden
$Shortcut.Description = "Razer-Control-Win Tray GUI"
$Shortcut.Save()

Write-Host "Tray auto-start installed successfully." -ForegroundColor Green
Write-Host "Shortcut: $ShortcutPath" -ForegroundColor DarkGray
