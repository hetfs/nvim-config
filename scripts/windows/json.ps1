[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# JSON external tools installer for the Neovim JSON language pack.
#
# Tools:
#   - Prettier: JSON, JSONC, and JSON5 formatting
#   - vscode-langservers-extracted: JSON and JSONC language server
#
# Requirements:
#   - Node.js
#   - npm
#
# Installs packages globally through npm. This script is intended to be
# run manually, not automatically during Neovim startup.

# ============================================================
# Configuration
# ============================================================

$Tools = @(
    @{
        Name     = "Prettier"
        Package  = "prettier"
        Version  = "3.9.10"
        Commands = @("prettier")
    },
    @{
        Name     = "VS Code language servers"
        Package  = "vscode-langservers-extracted"
        Version  = "4.10.0"
        Commands = @("vscode-json-language-server")
    }
)

# ============================================================
# Output helpers
# ============================================================

function Write-Info {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-Install {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host "[INSTALL] $Message" -ForegroundColor Yellow
}

function Write-Update {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host "[UPDATE] $Message" -ForegroundColor Yellow
}

function Write-Failure {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# ============================================================
# Prerequisites
# ============================================================

function Get-ApplicationPath {
    param([Parameter(Mandatory)][string]$Name)

    $Command = Get-Command $Name -CommandType Application -ErrorAction SilentlyContinue |
        Select-Object -First 1

    if ($null -eq $Command) {
        return $null
    }

    return $Command.Source
}

function Test-Prerequisites {
    Write-Info "Checking Node.js and npm prerequisites."

    $NodePath = Get-ApplicationPath -Name "node"
    $NpmPath = Get-ApplicationPath -Name "npm"

    if (-not $NodePath) {
        throw "node.exe is not available on PATH. Install Node.js and reopen PowerShell."
    }

    if (-not $NpmPath) {
        throw "npm is not available on PATH. Repair or reinstall Node.js, then reopen PowerShell."
    }

    $NodeOutput = & $NodePath --version 2>&1
    $NodeExitCode = $LASTEXITCODE

    if ($NodeExitCode -ne 0) {
        throw "Unable to determine the Node.js version: $($NodeOutput -join "`n")"
    }

    $NpmOutput = & $NpmPath --version 2>&1
    $NpmExitCode = $LASTEXITCODE

    if ($NpmExitCode -ne 0) {
        throw "Unable to determine the npm version: $($NpmOutput -join "`n")"
    }

    Write-Success "Node.js $(($NodeOutput -join '').Trim())"
    Write-Success "npm $(($NpmOutput -join '').Trim())"

    return $NpmPath
}

# ============================================================
# npm global installation directory and PATH
# ============================================================

function Get-NpmGlobalPrefix {
    param([Parameter(Mandatory)][string]$NpmPath)

    $Output = & $NpmPath prefix --global 2>&1
    $ExitCode = $LASTEXITCODE
    $Prefix = ($Output -join "`n").Trim()

    if ($ExitCode -ne 0 -or [string]::IsNullOrWhiteSpace($Prefix)) {
        throw "Unable to determine npm's global installation directory. Output: $Prefix"
    }

    if (-not (Test-Path -LiteralPath $Prefix -PathType Container)) {
        throw "npm's global installation directory does not exist: $Prefix"
    }

    return [IO.Path]::GetFullPath($Prefix)
}

function Test-PathContainsEntry {
    param(
        [AllowEmptyString()]
        [string]$PathValue,

        [Parameter(Mandatory)]
        [string]$Entry
    )

    $Target = [IO.Path]::GetFullPath(
        [Environment]::ExpandEnvironmentVariables($Entry.Trim().Trim('"'))
    )

    foreach ($CurrentEntry in ($PathValue -split ";")) {
        if ([string]::IsNullOrWhiteSpace($CurrentEntry)) {
            continue
        }

        $Expanded = [Environment]::ExpandEnvironmentVariables(
            $CurrentEntry.Trim().Trim('"')
        )

        try {
            $Normalized = [IO.Path]::GetFullPath($Expanded)
        }
        catch {
            continue
        }

        if ([string]::Equals(
            $Normalized,
            $Target,
            [StringComparison]::OrdinalIgnoreCase
        )) {
            return $true
        }
    }

    return $false
}

function Add-NpmGlobalPath {
    param([Parameter(Mandatory)][string]$Prefix)

    $UserPath = [Environment]::GetEnvironmentVariable("Path", "User")

    if (-not (Test-PathContainsEntry -PathValue $UserPath -Entry $Prefix)) {
        Write-Update "Adding npm global directory to persistent user PATH."

        $UserEntries = @(
            $UserPath -split ";" |
                Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        )

        $UserEntries += $Prefix

        [Environment]::SetEnvironmentVariable(
            "Path",
            ($UserEntries -join ";"),
            "User"
        )
    }
    else {
        Write-Success "npm global directory is already in persistent user PATH."
    }

    if (-not (Test-PathContainsEntry -PathValue $env:PATH -Entry $Prefix)) {
        $env:PATH = "$Prefix;$env:PATH"
        Write-Update "Added npm global directory to the current PowerShell PATH."
    }
    else {
        Write-Success "npm global directory is already in the current PATH."
    }

    Write-Success "npm global directory: $Prefix"
}

# ============================================================
# Package installation and verification
# ============================================================

function Test-NpmPackageVersion {
    param(
        [Parameter(Mandatory)][string]$NpmPath,
        [Parameter(Mandatory)][string]$Package,
        [Parameter(Mandatory)][string]$Version
    )

    $null = & $NpmPath list --global "$Package@$Version" --depth=0 2>$null
    return ($LASTEXITCODE -eq 0)
}

function Install-NpmPackage {
    param(
        [Parameter(Mandatory)][string]$NpmPath,
        [Parameter(Mandatory)][hashtable]$Tool
    )

    $PackageSpec = "$($Tool.Package)@$($Tool.Version)"

    if (Test-NpmPackageVersion `
        -NpmPath $NpmPath `
        -Package $Tool.Package `
        -Version $Tool.Version) {

        Write-Success "$($Tool.Name) $($Tool.Version) is already installed."
        return
    }

    Write-Install "Installing $PackageSpec globally."

    $InstallOutput = & $NpmPath install --global $PackageSpec 2>&1
    $InstallExitCode = $LASTEXITCODE

    if ($InstallExitCode -ne 0) {
        throw "npm failed to install $PackageSpec (exit code $InstallExitCode).`n$($InstallOutput -join "`n")"
    }

    if (-not (Test-NpmPackageVersion `
        -NpmPath $NpmPath `
        -Package $Tool.Package `
        -Version $Tool.Version)) {

        throw "Package verification failed for $PackageSpec after installation."
    }

    Write-Success "$($Tool.Name) $($Tool.Version) installed and verified."
}

function Test-ToolCommands {
    param([Parameter(Mandatory)][hashtable]$Tool)

    foreach ($CommandName in $Tool.Commands) {
        $ExecutablePath = Get-ApplicationPath -Name $CommandName

        if (-not $ExecutablePath) {
            throw @"
Required command '$CommandName' was not found on PATH.

npm global executable directory should be:
$(npm prefix --global)

Confirm that this directory is on PATH, then reopen PowerShell.
"@
        }

        Write-Success "$CommandName is available: $ExecutablePath"
    }
}

function Test-PrettierVersion {
    param([Parameter(Mandatory)][string]$ExpectedVersion)

    $PrettierPath = Get-ApplicationPath -Name "prettier"

    if (-not $PrettierPath) {
        throw "Prettier executable was not found on PATH."
    }

    $Output = & $PrettierPath --version 2>&1
    $ExitCode = $LASTEXITCODE
    $ActualVersion = ($Output -join "`n").Trim()

    if ($ExitCode -ne 0) {
        throw "Unable to execute Prettier: $ActualVersion"
    }

    if ($ActualVersion -ne $ExpectedVersion) {
        throw "Prettier version mismatch. Expected $ExpectedVersion, received $ActualVersion."
    }

    Write-Success "Prettier executable reports version $ActualVersion."
}

# ============================================================
# Main
# ============================================================

try {
    Write-Info "Starting JSON external tools installation."

    $NpmPath = Test-Prerequisites

    $NpmPrefix = Get-NpmGlobalPrefix -NpmPath $NpmPath
    Add-NpmGlobalPath -Prefix $NpmPrefix

    foreach ($Tool in $Tools) {
        Install-NpmPackage -NpmPath $NpmPath -Tool $Tool
        Test-ToolCommands -Tool $Tool
    }

    $PrettierTool = $Tools | Where-Object { $_.Package -eq "prettier" } |
        Select-Object -First 1

    Test-PrettierVersion -ExpectedVersion $PrettierTool.Version

    Write-Success "JSON external tools are installed and verified."
}
catch {
    Write-Failure $_.Exception.Message
    exit 1
}
