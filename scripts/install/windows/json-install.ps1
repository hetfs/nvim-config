# JSON external tools installer
# Installs and verifies the tools required by the Neovim JSON language pack.
#
# Tools:
#   - Prettier: JSON, JSONC and JSON5 formatting
#   - vscode-langservers-extracted: JSON and JSONC language server
#
# Requirements:
#   - Node.js
#   - npm

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# Tool versions
# ---------------------------------------------------------------------------

$Tools = @(
    @{
        Package = "prettier"
        Version = "3.9.10"
        Commands = @("prettier")
    }
    @{
        Package = "vscode-langservers-extracted"
        Version = "4.10.0"
        Commands = @("vscode-json-language-server")
    }
)

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
    Write-Info "Checking Node.js and npm prerequisites..."

    foreach ($Command in @("node", "npm")) {
        if (-not (Get-Command $Command -ErrorAction SilentlyContinue)) {
            throw "$Command is not available on PATH. Install Node.js and reopen PowerShell."
        }
    }

    $NodeVersion = (& node --version).Trim()

    if ($LASTEXITCODE -ne 0) {
        throw "Unable to determine the Node.js version."
    }

    $NpmVersion = (& npm --version).Trim()

    if ($LASTEXITCODE -ne 0) {
        throw "Unable to determine the npm version."
    }

    Write-Success "Node.js $NodeVersion"
    Write-Success "npm $NpmVersion"
}

# ---------------------------------------------------------------------------
# Package installation
# ---------------------------------------------------------------------------

function Test-NpmPackageVersion {
    param(
        [Parameter(Mandatory)]
        [string]$Package,

        [Parameter(Mandatory)]
        [string]$Version
    )

    $null = & npm list --global "$Package@$Version" --depth=0 2>$null

    return $LASTEXITCODE -eq 0
}

function Install-NpmPackage {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Tool
    )

    $Package = $Tool.Package
    $Version = $Tool.Version
    $PackageSpec = "$Package@$Version"

    if (Test-NpmPackageVersion -Package $Package -Version $Version) {
        Write-Success "$Package $Version is already installed."
        return
    }

    Write-Install "Installing $PackageSpec globally..."

    & npm install --global $PackageSpec

    if ($LASTEXITCODE -ne 0) {
        throw "npm failed to install $PackageSpec."
    }

    if (-not (Test-NpmPackageVersion -Package $Package -Version $Version)) {
        throw "Package verification failed for $PackageSpec."
    }

    Write-Success "$Package $Version installed and verified."
}

# ---------------------------------------------------------------------------
# Executable verification
# ---------------------------------------------------------------------------

function Test-ToolCommands {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Tool
    )

    foreach ($Command in $Tool.Commands) {
        if (-not (Get-Command $Command -ErrorAction SilentlyContinue)) {
            throw "$Command was not found on PATH. Check npm's global executable directory and reopen PowerShell."
        }

        Write-Success "$Command is available on PATH."
    }
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

try {
    Write-Info "Starting JSON tools installation."

    Test-Prerequisites

    foreach ($Tool in $Tools) {
        Install-NpmPackage -Tool $Tool
        Test-ToolCommands -Tool $Tool
    }

    Write-Success "JSON external tools are installed and verified."
}
catch {
    Write-Failure $_.Exception.Message
    exit 1
}
