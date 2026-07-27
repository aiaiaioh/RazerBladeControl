#Requires -Version 5.1
<#
    package.ps1 - one-shot release packager for Razer Blade Control.

    Produces, in .\dist :
        RazerBladeControl-v<version>-portable.zip
        RazerBladeControl-v<version>-setup.exe   (if Inno Setup is installed)

    The version is read from Cargo.toml, so cutting a release is:
        1. bump the version in Cargo.toml
        2. run this script

    Run from the project root:
        powershell -ExecutionPolicy Bypass -File .\package.ps1

    Requirements:
        - Rust toolchain (cargo) on PATH
        - Inno Setup 6 for the installer (https://jrsoftware.org/isdl.php) -
          if it's missing the script still builds the portable zip.
#>

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
Set-Location $root

# --- 1. Version from Cargo.toml (single source of truth) --------------------
$cargoToml = Join-Path $root "Cargo.toml"
if (-not (Test-Path $cargoToml)) { throw "Cargo.toml not found in $root" }
$verLine = Select-String -Path $cargoToml -Pattern '^\s*version\s*=\s*"([^"]+)"' | Select-Object -First 1
if (-not $verLine) { throw "Could not find a version = ""x.y.z"" line in Cargo.toml" }
$version = $verLine.Matches[0].Groups[1].Value
Write-Host "==> Packaging Razer Blade Control v$version" -ForegroundColor Cyan

# --- 2. Stop running instances so the build can overwrite the .exe files -----
foreach ($proc in "razer-gui", "razer-daemon") {
    Get-Process -Name $proc -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Host "    stopping running $($_.ProcessName)..." -ForegroundColor Yellow
        try   { Stop-Process -Id $_.Id -Force -ErrorAction Stop }
        catch { Write-Warning "could not stop $proc (elevated?). Close it manually if the build fails." }
    }
}

# --- 3. Build the release binaries (static CRT via .cargo\config.toml) -------
Write-Host "==> Building release binaries..." -ForegroundColor Cyan
cargo build --release --bin razer-gui --bin razer-daemon
if ($LASTEXITCODE -ne 0) { throw "cargo build failed" }

$relDir = Join-Path $root "target\release"
$gui    = Join-Path $relDir "razer-gui.exe"
$daemon = Join-Path $relDir "razer-daemon.exe"
foreach ($f in $gui, $daemon) {
    if (-not (Test-Path $f)) { throw "Expected build output missing: $f" }
}

# --- 4. Staging folder ------------------------------------------------------
$dist  = Join-Path $root "dist"
$stage = Join-Path $dist "RazerBladeControl-v$version"
if (Test-Path $stage) { Remove-Item $stage -Recurse -Force }
New-Item -ItemType Directory -Force -Path $stage | Out-Null

Copy-Item $gui, $daemon -Destination $stage
$readme = Join-Path $root "README.txt"
if (Test-Path $readme) { Copy-Item $readme -Destination $stage }
else { Write-Warning "README.txt not found in project root - it won't be bundled." }

# --- 5. Portable zip (extract -> one folder) --------------------------------
$zip = Join-Path $dist "RazerBladeControl-v$version-portable.zip"
if (Test-Path $zip) { Remove-Item $zip -Force }
Compress-Archive -Path $stage -DestinationPath $zip
Write-Host "==> Portable zip:  $zip" -ForegroundColor Green

# --- 6. Installer via Inno Setup (skipped gracefully if not installed) ------
$iss  = Join-Path $root "installer.iss"
$iscc = @(
    (Join-Path $env:ProgramFiles        "Inno Setup 7\ISCC.exe"),
    (Join-Path ${env:ProgramFiles(x86)} "Inno Setup 7\ISCC.exe")
) | Where-Object { Test-Path $_ } | Select-Object -First 1

if ($iscc -and (Test-Path $iss)) {
    Write-Host "==> Building installer with Inno Setup..." -ForegroundColor Cyan
    & $iscc "/DMyAppVersion=$version" "/DSrcDir=$relDir" "/DOutputDir=$dist" $iss
    if ($LASTEXITCODE -ne 0) { throw "Inno Setup compile failed" }
    Write-Host "==> Installer:     $(Join-Path $dist ""RazerBladeControl-v$version-setup.exe"")" -ForegroundColor Green
}
else {
    Write-Warning "Inno Setup not found (or installer.iss missing) - skipped the setup.exe."
    Write-Warning "Install it from https://jrsoftware.org/isdl.php and re-run for the installer."
}

Write-Host "`n==> Done. Artifacts are in: $dist" -ForegroundColor Cyan
