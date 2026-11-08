# Install and verify SQL Formatter for the nvim-config SQL language pack.
#
# Usage:
#   .\scripts\core\windows\sql-formatter-install.ps1
#   .\scripts\core\windows\sql-formatter-install.ps1 -Force
#
# Requirements:
#   - Node.js
#   - npm
#
# Installation:
#   - Package: sql-formatter
#   - Version: 15.9.0
#   - Scope: npm global
#
# Neovim does not install or update this tool.

[CmdletBinding()]
param(
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Package = "sql-formatter"
$Version = "15.9.0"
$PackageSpec = "$Package@$Version"
$Command = "sql-formatter"

# ============================================================
# Output
# ============================================================

function Write-Status {
    param(
        [ValidateSet("INFO", "OK", "SKIP", "INSTALL", "FAIL")]
        [string]$Level,

        [string]$Message
    )

    $Color = switch ($Level) {
        "OK" { "Green" }
        "SKIP" { "Cyan" }
        "INSTALL" { "Yellow" }
        "FAIL" { "Red" }
        default { "Gray" }
    }

    Write-Host "[$Level] $Message" -ForegroundColor $Color
}

# ============================================================
# Command Discovery
# ============================================================

function Get-Application {
    param(
        [string[]]$Names
    )

    foreach ($Name in $Names) {
        $Application = Get-Command `
            -Name $Name `
            -CommandType Application `
            -ErrorAction SilentlyContinue |
            Select-Object -First 1

        if ($Application) {
            return $Application
        }
    }

    return $null
}

# ============================================================
# Prerequisites
# ============================================================

function Test-Prerequisites {
    $script:Node = Get-Application -Names @("node.exe", "node")
    $script:Npm = Get-Application -Names @("npm.cmd", "npm")

    if (-not $script:Node) {
        throw "Node.js was not found. Install Node.js before running this installer."
    }

    if (-not $script:Npm) {
        throw "npm was not found. Verify that npm is installed and available on PATH."
    }

    $NodeVersion = (& $script:Node.Source --version 2>&1 | Out-String).Trim()

    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($NodeVersion)) {
        throw "Unable to determine the Node.js version."
    }

    $NpmVersion = (& $script:Npm.Source --version 2>&1 | Out-String).Trim()

    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($NpmVersion)) {
        throw "Unable to determine the npm version."
    }

    Write-Status "OK" "Node.js: $NodeVersion"
    Write-Status "OK" "npm: $NpmVersion"
}

# ============================================================
# npm Global Prefix
# ============================================================

function Get-NpmGlobalPrefix {
    $Prefix = (& $script:Npm.Source prefix --global 2>&1 | Out-String).Trim()

    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($Prefix)) {
        throw "Unable to determine the npm global prefix."
    }

    if (-not (Test-Path -LiteralPath $Prefix -PathType Container)) {
        throw "The npm global prefix does not exist: $Prefix"
    }

    return $Prefix
}

function Test-PathEntry {
    param(
        [string]$PathValue,
        [string]$Entry
    )

    if ([string]::IsNullOrWhiteSpace($PathValue)) {
        return $false
    }

    $NormalizedEntry = $Entry.TrimEnd("\", "/")

    foreach ($CurrentEntry in ($PathValue -split ";")) {
        if ([string]::IsNullOrWhiteSpace($CurrentEntry)) {
            continue
        }

        $NormalizedCurrent = $CurrentEntry.Trim().TrimEnd("\", "/")

        if ([string]::Equals(
                $NormalizedCurrent,
                $NormalizedEntry,
                [System.StringComparison]::OrdinalIgnoreCase
            )) {
            return $true
        }
    }

    return $false
}

function Add-NpmGlobalPath {
    param(
        [string]$Prefix
    )

    # Persist the npm global prefix for the current user.
    $UserPath = [Environment]::GetEnvironmentVariable("Path", "User")

    if (-not (Test-PathEntry -PathValue $UserPath -Entry $Prefix)) {
        $UpdatedUserPath = if ([string]::IsNullOrWhiteSpace($UserPath)) {
            $Prefix
        }
        else {
            "$UserPath;$Prefix"
        }

        [Environment]::SetEnvironmentVariable(
            "Path",
            $UpdatedUserPath,
            "User"
        )

        Write-Status "OK" "Added npm global prefix to the user PATH."
    }
    else {
        Write-Status "SKIP" "npm global prefix is already in the user PATH."
    }

    # Make the prefix available to this PowerShell process.
    if (-not (Test-PathEntry -PathValue $env:Path -Entry $Prefix)) {
        $env:Path = "$Prefix;$env:Path"
        Write-Status "OK" "Added npm global prefix to the current session PATH."
    }
}

# ============================================================
# Package Verification
# ============================================================

function Test-NpmPackageVersion {
    $null = & $script:Npm.Source list --global $PackageSpec --depth=0 2>&1

    return $LASTEXITCODE -eq 0
}

function Test-CommandVersion {
    $Application = Get-Application -Names @($Command)

    if (-not $Application) {
        throw "$Command was not found after installation."
    }

    $ActualVersion = (& $Application.Source --version 2>&1 | Out-String).Trim()

    if ($LASTEXITCODE -ne 0) {
        throw "Unable to execute $Command --version."
    }

    if ($ActualVersion -ne $Version) {
        throw "Unexpected $Command version. Expected $Version, found '$ActualVersion'."
    }

    Write-Status "OK" "$Command version: $ActualVersion"
}

# ============================================================
# Installation
# ============================================================

function Install-SqlFormatter {
    if ((Test-NpmPackageVersion) -and -not $Force) {
        Write-Status "SKIP" "$PackageSpec is already installed."
        return
    }

    if ($Force) {
        Write-Status "INSTALL" "Removing the existing global $Package package before reinstalling."

        $null = & $script:Npm.Source uninstall --global $Package 2>&1

        if ($LASTEXITCODE -ne 0) {
            throw "Unable to remove the existing global $Package installation."
        }
    }

    Write-Status "INSTALL" "Installing $PackageSpec globally."

    & $script:Npm.Source install --global $PackageSpec

    if ($LASTEXITCODE -ne 0) {
        throw "npm failed to install $PackageSpec."
    }

    if (-not (Test-NpmPackageVersion)) {
        throw "npm did not report the expected global package version: $PackageSpec."
    }

    Write-Status "OK" "Installed $PackageSpec."
}

# ============================================================
# Main
# ============================================================

try {
    Write-Status "INFO" "Starting SQL Formatter installation."

    Test-Prerequisites

    $NpmPrefix = Get-NpmGlobalPrefix
    Write-Status "INFO" "npm global prefix: $NpmPrefix"

    Add-NpmGlobalPath -Prefix $NpmPrefix

    Install-SqlFormatter
    Test-CommandVersion

    Write-Status "OK" "SQL Formatter installation and verification completed."
    exit 0
}
catch {
    Write-Status "FAIL" $_.Exception.Message
    exit 1
}
