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
# Logging
# --------------------------------------------------

function Log {
    param([string]$Message)

    $Time = Get-Date -Format "HH:mm:ss"
    Write-Host "[$Time] $Message"
}


# --------------------------------------------------
# Start
# --------------------------------------------------

Clear-Host

Write-Host ""
Write-Host "PBDKMAP"
Write-Host ""

try {

    # --------------------------------------------------
    # Temporary workspace
    # --------------------------------------------------

    Log "Creating temporary workspace"

    New-Item `
        -ItemType Directory `
        -Path $TempDir `
        | Out-Null


    # --------------------------------------------------
    # Configuration
    # --------------------------------------------------

    Log "Downloading configuration"

    $ConfigPath = Join-Path $TempDir "kanata.kbd"

    Invoke-WebRequest `
        -Uri $ConfigURL `
        -OutFile $ConfigPath

    Log "Configuration downloaded"


    # --------------------------------------------------
    # Kanata download
    # --------------------------------------------------

    Log "Downloading Kanata $KanataVersion"

    $ZipPath = Join-Path $TempDir "kanata.zip"

    Invoke-WebRequest `
        -Uri $KanataZipURL `
        -OutFile $ZipPath

    Log "Kanata downloaded"


    # --------------------------------------------------
    # Verification
    # --------------------------------------------------

    Log "Verifying SHA-256"

    $ActualSHA256 = (
        Get-FileHash `
            -Path $ZipPath `
            -Algorithm SHA256
    ).Hash.ToLower()

    if ($ActualSHA256 -ne $ExpectedSHA256) {

        throw @"
SHA-256 verification failed.

Expected:
$ExpectedSHA256

Received:
$ActualSHA256
"@

    }

    Log "SHA-256 verified"


    # --------------------------------------------------
    # Extraction
    # --------------------------------------------------

    Log "Extracting Kanata"

    Expand-Archive `
        -Path $ZipPath `
        -DestinationPath $TempDir `
        -Force

    Log "Kanata extracted"


    # --------------------------------------------------
    # Find executable
    # --------------------------------------------------

    Log "Locating WinIOv2 executable"

    $KanataExe = Get-ChildItem `
        -Path $TempDir `
        -Recurse `
        -File |
        Where-Object {
            $_.Name -eq "kanata_windows_gui_winIOv2_x64.exe"
        } |
        Select-Object -First 1

    if (-not $KanataExe) {
        throw "Kanata WinIOv2 executable not found."
    }

    Log "Executable found"


    # --------------------------------------------------
    # Kanata logs
    # --------------------------------------------------

    $StdOutLog = Join-Path $TempDir "kanata-stdout.log"
    $StdErrLog = Join-Path $TempDir "kanata-stderr.log"


    # --------------------------------------------------
    # Start Kanata
    # --------------------------------------------------

    Log "Starting Kanata"

    $Kanata = Start-Process `
        -FilePath $KanataExe.FullName `
        -ArgumentList "--cfg `"$ConfigPath`"" `
        -RedirectStandardOutput $StdOutLog `
        -RedirectStandardError $StdErrLog `
        -PassThru

    Start-Sleep -Seconds 2


    # --------------------------------------------------
    # Check startup
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


    Log "PBDKMAP ACTIVE"

    Write-Host ""
    Write-Host "Press ENTER to stop."
    Write-Host ""

    Read-Host | Out-Null

}
catch {

    Write-Host ""
    Log "ERROR"

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

                Log "Stopping Kanata"

                Stop-Process `
                    -Id $Kanata.Id `
                    -Force `
                    -ErrorAction SilentlyContinue

                $Kanata.WaitForExit()

                Log "Kanata stopped"
            }

        }
        catch {

            Log "Warning: unable to cleanly stop Kanata"

        }

    }


    # --------------------------------------------------
    # Cleanup
    # --------------------------------------------------

    if (Test-Path $TempDir) {

        Log "Deleting temporary files"

        Remove-Item `
            -Path $TempDir `
            -Recurse `
            -Force `
            -ErrorAction SilentlyContinue

        if (Test-Path $TempDir) {
            Log "Warning: temporary directory could not be fully removed"
        }
        else {
            Log "Temporary files deleted"
        }

    }


    Log "PBDKMAP STOPPED"

    Write-Host ""
}