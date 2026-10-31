# TOML external tools installer
# Installs and verifies the tools required by the Neovim TOML language pack.
#
# Tools:
#   - Taplo: TOML language server and formatter
#
# Requirements:
#   - Windows Package Manager (winget)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# Tool configuration
# ---------------------------------------------------------------------------

$Tool = @{
    PackageId = "tamasfe.taplo"
    Version   = "0.10.0"
    Command   = "taplo"
}

# ---------------------------------------------------------------------------
# Output helpers
# ---------------------------------------------------------------------------

function Write-Info {
    param([string]$Message)

    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)

    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-Install {
    param([string]$Message)

    Write-Host "[INSTALL] $Message" -ForegroundColor Yellow
}

function Write-Update {
    param([string]$Message)

    Write-Host "[UPDATE] $Message" -ForegroundColor Yellow
}

function Write-Failure {
    param([string]$Message)

    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# ---------------------------------------------------------------------------
# Prerequisites
# ---------------------------------------------------------------------------

function Test-Prerequisites {
    Write-Info "Checking Windows Package Manager..."

    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        throw "winget is not available. Install or update App Installer from the Microsoft Store."
    }

    $WingetVersion = (& winget --version | Out-String).Trim()

    if ($LASTEXITCODE -ne 0) {
        throw "Unable to determine the WinGet version."
    }

    Write-Success "WinGet $WingetVersion"
}

# ---------------------------------------------------------------------------
# Installation
# ---------------------------------------------------------------------------

function Test-WingetPackage {
    param(
        [Parameter(Mandatory)]
        [string]$PackageId
    )

    $null = & winget list --id $PackageId --exact --accept-source-agreements 2>$null

    return $LASTEXITCODE -eq 0
}

function Install-Taplo {
    $PackageId = $Tool.PackageId

    if (Test-WingetPackage -PackageId $PackageId) {
        Write-Success "Taplo is already installed."
        return
    }

    Write-Install "Installing Taplo through WinGet..."

    & winget install `
        --id $PackageId `
        --exact `
        --accept-source-agreements `
        --accept-package-agreements

    if ($LASTEXITCODE -ne 0) {
        throw "WinGet failed to install Taplo."
    }

    Write-Success "Taplo installation completed."
}

# ---------------------------------------------------------------------------
# Executable verification
# ---------------------------------------------------------------------------

function Test-Taplo {
    $Executable = Get-Command $Tool.Command -ErrorAction SilentlyContinue

    if (-not $Executable) {
        throw "taplo was not found on PATH. Reopen PowerShell or check the installation."
    }

    $ReportedVersion = (& taplo --version | Out-String).Trim()

    if ($LASTEXITCODE -ne 0) {
        throw "Unable to execute Taplo."
    }

    if ($ReportedVersion -notmatch "(^|\s)v?$([regex]::Escape($Tool.Version))($|\s)") {
        throw "Taplo version mismatch. Expected $($Tool.Version), received $ReportedVersion."
    }

    Write-Success "Taplo $ReportedVersion"
    Write-Success "Executable: $($Executable.Source)"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

try {
    Write-Info "Starting TOML external tools installation."

    Test-Prerequisites
    Install-Taplo
    Test-Taplo

    Write-Success "TOML external tools are installed and verified."
}
catch {
    Write-Failure $_.Exception.Message
    exit 1
}
