$ErrorActionPreference = "Stop"

$TempDir = Join-Path $env:TEMP ("pubudu-kanata-" + [guid]::NewGuid())
$Kanata = $null

# Pin the version so an upstream update can't unexpectedly break things
$KanataVersion = "v1.12.0"

$ConfigURL = "https://raw.githubusercontent.com/pgwijesinghe/pbdkanata/master/kanata.kbd"
$KanataZipURL = "https://github.com/jtroo/kanata/releases/download/$KanataVersion/kanata-windows-binaries-x64-$KanataVersion.zip"

New-Item -ItemType Directory -Path $TempDir | Out-Null

try {
    Clear-Host

    Write-Host ""
    Write-Host "  ======================================"
    Write-Host "       PUBUDUW'S CUSTOM KANATA"
    Write-Host "  ======================================"
    Write-Host ""
    Write-Host "  Preparing keyboard..."
    Write-Host ""

    # Download config
    $ConfigPath = Join-Path $TempDir "kanata.kbd"
    Invoke-WebRequest $ConfigURL -OutFile $ConfigPath

    Write-Host "  [OK] Configuration downloaded"

    # Download Kanata
    $ZipPath = Join-Path $TempDir "kanata.zip"
    Invoke-WebRequest $KanataZipURL -OutFile $ZipPath

    Write-Host "  [OK] Kanata $KanataVersion downloaded"

    # Extract
    Expand-Archive $ZipPath -DestinationPath $TempDir

    Write-Host "  [OK] Kanata extracted"

    # We don't use cmd actions, so use the safer non-cmd WinIOv2 GUI build
    $KanataExe = Get-ChildItem $TempDir -Recurse -File |
        Where-Object {
            $_.Name -eq "kanata_windows_gui_winIOv2_x64.exe"
        } |
        Select-Object -First 1

    if (-not $KanataExe) {
        throw "Could not find kanata_windows_gui_winIOv2_x64.exe"
    }

    # Start Kanata
    $Kanata = Start-Process `
        -FilePath $KanataExe.FullName `
        -ArgumentList "--cfg `"$ConfigPath`"" `
        -PassThru

    Start-Sleep -Seconds 1

    if ($Kanata.HasExited) {
        throw "Kanata exited immediately. Check your kanata.kbd configuration."
    }

    Clear-Host

    Write-Host ""
    Write-Host "  ======================================"
    Write-Host "       PUBUDUW'S CUSTOM KANATA"
    Write-Host "  ======================================"
    Write-Host ""
    Write-Host "              [ ACTIVE ]"
    Write-Host ""
    Write-Host "  Tap Caps        -> Esc"
    Write-Host "  Caps + H/J/K/L  -> Navigation"
    Write-Host "  Caps + I        -> Up"
    Write-Host "  Caps + U/O      -> Home / End"
    Write-Host "  Caps + C        -> Copy"
    Write-Host "  Caps + X        -> Cut"
    Write-Host "  Caps + V        -> Paste"
    Write-Host "  Shift + Shift   -> Caps Lock"
    Write-Host ""
    Write-Host "  Keep this window open."
    Write-Host "  Press ENTER to stop."
    Write-Host ""

    Read-Host
}
finally {
    Write-Host ""
    Write-Host "  Stopping Kanata..."

    if ($Kanata -and -not $Kanata.HasExited) {
        Stop-Process -Id $Kanata.Id -Force -ErrorAction SilentlyContinue
    }

    Start-Sleep -Milliseconds 500

    Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue

    Write-Host "  Temporary files deleted."
    Write-Host "  Normal keyboard restored."
    Write-Host ""
}