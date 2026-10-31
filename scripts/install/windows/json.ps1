# JSON external tools installer
# Installs and verifies the tools required by the Neovim JSON language pack.
#
# Tools:
#   - Prettier: JSON, JSONC, and JSON5 formatting
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
        Package  = "prettier"
        Version  = "3.9.10"
        Commands = @("prettier")
    }
    @{
        Package  = "vscode-langservers-extracted"
        Version  = "4.10.0"
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

    $NodeVersion = (& node --version | Out-String).Trim()

    if ($LASTEXITCODE -ne 0) {
        throw "Unable to determine the Node.js version."
    }

    $NpmVersion = (& npm --version | Out-String).Trim()

    if ($LASTEXITCODE -ne 0) {
        throw "Unable to determine the npm version."
    }

    Write-Success "Node.js $NodeVersion"
    Write-Success "npm $NpmVersion"
}

# ---------------------------------------------------------------------------
# npm global PATH
# ---------------------------------------------------------------------------

function Get-NpmGlobalPrefix {
    $Prefix = (& npm prefix --global | Out-String).Trim()

    if ($LASTEXITCODE -ne 0 -or -not $Prefix) {
        throw "Unable to determine npm's global installation directory."
    }

    if (-not (Test-Path $Prefix -PathType Container)) {
        throw "npm's global installation directory does not exist: $Prefix"
    }

    return $Prefix
}

function Test-PathEntry {
    param(
        [Parameter(Mandatory)]
        [string]$PathValue,

        [Parameter(Mandatory)]
        [string]$Entry
    )

    foreach ($CurrentEntry in ($PathValue -split ";")) {
        if (
            $CurrentEntry.Trim().TrimEnd("\") -ieq
            $Entry.Trim().TrimEnd("\")
        ) {
            return $true
        }
    }

    return $false
}

function Add-NpmGlobalPath {
    param(
        [Parameter(Mandatory)]
        [string]$Prefix
    )

    # Update the persistent user PATH.
    $UserPath = [Environment]::GetEnvironmentVariable("Path", "User")

    if (-not (Test-PathEntry -PathValue $UserPath -Entry $Prefix)) {
        Write-Update "Adding npm global directory to the user PATH."

        $UserEntries = @(
            $UserPath -split ";" |
                Where-Object { $_ -and $_.Trim() }
        )

        $NewUserPath = (@($UserEntries) + $Prefix) -join ";"

        [Environment]::SetEnvironmentVariable(
            "Path",
            $NewUserPath,
            "User"
        )
    }

    # Update the current PowerShell session.
    if (-not (Test-PathEntry -PathValue $env:PATH -Entry $Prefix)) {
        $env:PATH = "$Prefix;$env:PATH"
    }

    Write-Success "npm global directory is available on PATH: $Prefix"
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
        $Executable = Get-Command $Command -ErrorAction SilentlyContinue

        if (-not $Executable) {
            throw "$Command was not found on PATH. Check npm's global executable directory."
        }

        Write-Success "$Command is available: $($Executable.Source)"
    }
}

function Test-PrettierVersion {
    $Output = (& prettier --version | Out-String).Trim()

    if ($LASTEXITCODE -ne 0) {
        throw "Unable to execute Prettier."
    }

    $ExpectedVersion = ($Tools | Where-Object {
        $_.Package -eq "prettier"
    }).Version

    if ($Output -ne $ExpectedVersion) {
        throw "Prettier version mismatch. Expected $ExpectedVersion, received $Output."
    }

    Write-Success "Prettier executable reports version $Output."
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

try {
    Write-Info "Starting JSON external tools installation."

    Test-Prerequisites

    $NpmPrefix = Get-NpmGlobalPrefix
    Add-NpmGlobalPath -Prefix $NpmPrefix

    foreach ($Tool in $Tools) {
        Install-NpmPackage -Tool $Tool
        Test-ToolCommands -Tool $Tool
    }

    Test-PrettierVersion

    Write-Success "JSON external tools are installed and verified."
}
catch {
    Write-Failure $_.Exception.Message
    exit 1
}
