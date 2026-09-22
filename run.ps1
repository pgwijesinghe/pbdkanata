$ErrorActionPreference = "Stop"

# --------------------------------------------------
# Configuration
# --------------------------------------------------

$KanataVersion = "v1.12.0"

$ConfigURL = "https://raw.githubusercontent.com/pgwijesinghe/pbdkanata/master/kanata.kbd"

$KanataZipURL = "https://github.com/jtroo/kanata/releases/download/$KanataVersion/windows-binaries-x64.zip"

# Official SHA-256 for Kanata v1.12.0 windows-binaries-x64.zip
$ExpectedSHA256 = "13947ed78cfa3284bfef854e3c542c74ab366236b72fd9f7e039f8638deead9d"

$TempDir = Join-Path $env:TEMP ("pbdkanata-" + [guid]::NewGuid())

$Kanata = $null


# --------------------------------------------------
# Create temporary workspace
# --------------------------------------------------

New-Item -ItemType Directory -Path $TempDir | Out-Null


try {

    Clear-Host

    Write-Host ""
    Write-Host "  ======================================"
    Write-Host "          PUBUDUW'S KANATA"
    Write-Host "  ======================================"
    Write-Host ""
    Write-Host "  Preparing keyboard..."
    Write-Host ""


    # --------------------------------------------------
    # Download configuration
    # --------------------------------------------------

    $ConfigPath = Join-Path $TempDir "kanata.kbd"

    Invoke-WebRequest `
        -Uri $ConfigURL `
        -OutFile $ConfigPath

    Write-Host "  [OK] Configuration downloaded"


    # --------------------------------------------------
    # Download Kanata
    # --------------------------------------------------

    $ZipPath = Join-Path $TempDir "kanata.zip"

    Invoke-WebRequest `
        -Uri $KanataZipURL `
        -OutFile $ZipPath

    Write-Host "  [OK] Kanata $KanataVersion downloaded"


    # --------------------------------------------------
    # Verify official Kanata binary
    # --------------------------------------------------

    Write-Host "  [..] Verifying Kanata..."

    $ActualSHA256 = (Get-FileHash `
        -Path $ZipPath `
        -Algorithm SHA256).Hash.ToLower()

    if ($ActualSHA256 -ne $ExpectedSHA256) {

        throw @"
Kanata SHA-256 verification FAILED.

Expected:
$ExpectedSHA256

Received:
$ActualSHA256

The downloaded binary will NOT be executed.
"@

    }

    Write-Host "  [OK] SHA-256 verified"


    # --------------------------------------------------
    # Extract
    # --------------------------------------------------

    Expand-Archive `
        -Path $ZipPath `
        -DestinationPath $TempDir `
        -Force

    Write-Host "  [OK] Kanata extracted"


    # --------------------------------------------------
    # Locate WinIOv2 GUI executable
    #
    # We deliberately use the non-cmd_allowed version.
    # Your config does not need command execution.
    # --------------------------------------------------

    $KanataExe = Get-ChildItem `
        -Path $TempDir `
        -Recurse `
        -File |
        Where-Object {
            $_.Name -eq "kanata_windows_gui_winIOv2_x64.exe"
        } |
        Select-Object -First 1


    if (-not $KanataExe) {

        Write-Host ""
        Write-Host "Files found in Kanata package:"
        Get-ChildItem $TempDir -Recurse -File |
            ForEach-Object {
                Write-Host "  $($_.Name)"
            }

        throw "Could not find kanata_windows_gui_winIOv2_x64.exe"
    }


    # --------------------------------------------------
    # Start Kanata
    # --------------------------------------------------

    Write-Host "  [..] Starting Kanata..."

    $Kanata = Start-Process `
        -FilePath $KanataExe.FullName `
        -ArgumentList "--cfg `"$ConfigPath`"" `
        -PassThru


    # Give Kanata time to parse config/start hooks
    Start-Sleep -Seconds 2


    # Make sure it didn't immediately crash
    if ($Kanata.HasExited) {
        throw "Kanata exited immediately. Check kanata.kbd."
    }


    # --------------------------------------------------
    # Active screen
    # --------------------------------------------------

    Clear-Host

    Write-Host ""
    Write-Host "  ======================================"
    Write-Host "          PUBUDUW'S KANATA"
    Write-Host "  ======================================"
    Write-Host ""
    Write-Host "              [ ACTIVE ]"
    Write-Host ""
    Write-Host "  Tap Caps         -> Esc"
    Write-Host ""
    Write-Host "  Caps + H         -> Ctrl + Left"
    Write-Host "  Caps + J         -> Left"
    Write-Host "  Caps + K         -> Down"
    Write-Host "  Caps + L         -> Right"
    Write-Host "  Caps + ;         -> Ctrl + Right"
    Write-Host ""
    Write-Host "  Caps + I         -> Up"
    Write-Host "  Caps + U         -> Home"
    Write-Host "  Caps + O         -> End"
    Write-Host ""
    Write-Host "  Caps + '         -> Backspace"
    Write-Host "  Caps + [         -> Ctrl + Backspace"
    Write-Host ""
    Write-Host "  Caps + C         -> Copy"
    Write-Host "  Caps + X         -> Cut"
    Write-Host "  Caps + V         -> Paste"
    Write-Host ""
    Write-Host "  LShift + RShift  -> Caps Lock"
    Write-Host ""
    Write-Host "  --------------------------------------"
    Write-Host ""
    Write-Host "  Keep this terminal open."
    Write-Host ""
    Write-Host "  Press ENTER to stop Kanata."
    Write-Host ""


    Read-Host | Out-Null

}
catch {

    Write-Host ""
    Write-Host "  ======================================"
    Write-Host "               ERROR"
    Write-Host "  ======================================"
    Write-Host ""
    Write-Host "  $($_.Exception.Message)"
    Write-Host ""

}
finally {

    # --------------------------------------------------
    # Stop Kanata
    # --------------------------------------------------

    Write-Host ""
    Write-Host "  Stopping Kanata..."


    if ($Kanata) {

        try {

            if (-not $Kanata.HasExited) {

                Stop-Process `
                    -Id $Kanata.Id `
                    -Force `
                    -ErrorAction SilentlyContinue

            }

        }
        catch {
            # Ignore cleanup errors
        }

    }


    Start-Sleep -Milliseconds 500


    # --------------------------------------------------
    # Remove temporary files
    # --------------------------------------------------

    Remove-Item `
        -Path $TempDir `
        -Recurse `
        -Force `
        -ErrorAction SilentlyContinue


    Write-Host "  Temporary files deleted."
    Write-Host "  Normal keyboard restored."
    Write-Host ""
}