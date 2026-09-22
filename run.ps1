$ErrorActionPreference = "Stop"

# --------------------------------------------------
# Configuration
# --------------------------------------------------

$KanataVersion = "v1.12.0"

$ConfigURL = "https://raw.githubusercontent.com/pgwijesinghe/pbdkanata/master/kanata.kbd"

$KanataZipURL = "https://github.com/jtroo/kanata/releases/download/$KanataVersion/windows-binaries-x64.zip"

$ExpectedSHA256 = "13947ed78cfa3284bfef854e3c542c74ab366236b72fd9f7e039f8638deead9d"

$TempDir = Join-Path $env:TEMP ("pbdkanata-" + [guid]::NewGuid())

$Kanata = $null


# --------------------------------------------------
# Create temporary workspace
# --------------------------------------------------

New-Item -ItemType Directory -Path $TempDir | Out-Null


try {

    Clear-Host
    Write-Host "Starting PBDKMAP..."


    # --------------------------------------------------
    # Download config
    # --------------------------------------------------

    $ConfigPath = Join-Path $TempDir "kanata.kbd"

    Invoke-WebRequest `
        -Uri $ConfigURL `
        -OutFile $ConfigPath


    # --------------------------------------------------
    # Download Kanata
    # --------------------------------------------------

    $ZipPath = Join-Path $TempDir "kanata.zip"

    Invoke-WebRequest `
        -Uri $KanataZipURL `
        -OutFile $ZipPath


    # --------------------------------------------------
    # Verify Kanata
    # --------------------------------------------------

    $ActualSHA256 = (
        Get-FileHash `
            -Path $ZipPath `
            -Algorithm SHA256
    ).Hash.ToLower()

    if ($ActualSHA256 -ne $ExpectedSHA256) {
        throw "Kanata download failed SHA-256 verification."
    }


    # --------------------------------------------------
    # Extract Kanata
    # --------------------------------------------------

    Expand-Archive `
        -Path $ZipPath `
        -DestinationPath $TempDir `
        -Force


    # --------------------------------------------------
    # Find WinIOv2 executable
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
        throw "Kanata executable not found."
    }


    # --------------------------------------------------
    # Start Kanata silently
    # --------------------------------------------------

    $StdOutLog = Join-Path $TempDir "kanata-stdout.log"
    $StdErrLog = Join-Path $TempDir "kanata-stderr.log"

    $Kanata = Start-Process `
        -FilePath $KanataExe.FullName `
        -ArgumentList "--cfg `"$ConfigPath`"" `
        -RedirectStandardOutput $StdOutLog `
        -RedirectStandardError $StdErrLog `
        -PassThru


    # Give Kanata time to initialize
    Start-Sleep -Seconds 2


    # --------------------------------------------------
    # Detect startup failure
    # --------------------------------------------------

    if ($Kanata.HasExited) {

        $KanataError = ""

        if (Test-Path $StdErrLog) {
            $KanataError = Get-Content $StdErrLog -Raw
        }

        if (-not $KanataError -and (Test-Path $StdOutLog)) {
            $KanataError = Get-Content $StdOutLog -Raw
        }

        if ($KanataError) {
            throw "Kanata failed to start:`n`n$KanataError"
        }

        throw "Kanata failed to start."
    }


    # --------------------------------------------------
    # Active
    # --------------------------------------------------

    Clear-Host

    Write-Host ""
    Write-Host "PBDKMAP [ACTIVE]"
    Write-Host ""
    Write-Host "Press ENTER to stop."
    Write-Host ""

    Read-Host | Out-Null

}
catch {

    Clear-Host

    Write-Host ""
    Write-Host "PBDKMAP [ERROR]"
    Write-Host ""
    Write-Host $_.Exception.Message
    Write-Host ""

}
finally {

    # --------------------------------------------------
    # Stop Kanata
    # --------------------------------------------------

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
    # Delete everything
    # --------------------------------------------------

    Remove-Item `
        -Path $TempDir `
        -Recurse `
        -Force `
        -ErrorAction SilentlyContinue


    Clear-Host

    Write-Host ""
    Write-Host "PBDKMAP [STOPPED]"
    Write-Host ""
}