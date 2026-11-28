# Install and verify SQL Formatter and SQLS for the nvim-config SQL language pack.
#
# Usage:
#   .\scripts\core\windows\sql-tools-install.ps1
#   .\scripts\core\windows\sql-tools-install.ps1 -Force
#
# Requirements:
#   - Windows
#   - PowerShell 7+
#   - Node.js and npm
#   - Go
#
# Installation:
#   - sql-formatter 15.9.0 through npm global
#   - sqls 0.2.48 through go install
#
# This script does not install Node.js, npm, or Go, configure database
# connections, or run automatically during Neovim startup.

[CmdletBinding()]
param(
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

$script:SqlFormatterPackage = 'sql-formatter'
$script:SqlFormatterVersion = '15.9.0'
$script:SqlFormatterSpec = "$($script:SqlFormatterPackage)@$($script:SqlFormatterVersion)"
$script:SqlFormatterCommand = 'sql-formatter'

$script:SqlsModule = 'github.com/sqls-server/sqls'
$script:SqlsVersion = '0.2.48'
$script:SqlsPackage = "$($script:SqlsModule)@v$($script:SqlsVersion)"
$script:SqlsExecutable = 'sqls.exe'

$script:Node = $null
$script:Npm = $null
$script:Go = $null

# ---------------------------------------------------------------------------
# Status reporting
# ---------------------------------------------------------------------------

function Write-Status {
    param(
        [ValidateSet('INFO', 'PASS', 'SKIP', 'INSTALL', 'UPDATE', 'FAIL')]
        [string]$Status,

        [Parameter(Mandatory)]
        [string]$Message
    )

    $color = switch ($Status) {
        'INFO'    { 'Cyan' }
        'PASS'    { 'Green' }
        'SKIP'    { 'DarkGray' }
        'INSTALL' { 'Yellow' }
        'UPDATE'  { 'Yellow' }
        'FAIL'    { 'Red' }
    }

    Write-Host "[$Status] $Message" -ForegroundColor $color
}

# ---------------------------------------------------------------------------
# Command discovery and platform checks
# ---------------------------------------------------------------------------

function Get-Application {
    param(
        [Parameter(Mandatory)]
        [string[]]$Names
    )

    foreach ($name in $Names) {
        $application = Get-Command `
            -Name $name `
            -CommandType Application `
            -ErrorAction SilentlyContinue |
            Select-Object -First 1

        if ($application) {
            return $application
        }
    }

    return $null
}

function Test-Platform {
    if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
        throw 'This installer supports Windows only.'
    }

    if ($PSVersionTable.PSVersion.Major -lt 7) {
        throw 'PowerShell 7 or later is required.'
    }

    Write-Status PASS "Windows and PowerShell $($PSVersionTable.PSVersion) detected."
}

# ---------------------------------------------------------------------------
# Prerequisites
# ---------------------------------------------------------------------------

function Test-Prerequisites {
    $script:Node = Get-Application -Names @('node.exe', 'node')
    $script:Npm = Get-Application -Names @('npm.cmd', 'npm')
    $script:Go = Get-Application -Names @('go.exe', 'go')

    if (-not $script:Node) {
        throw 'Node.js was not found. Install Node.js before running this installer.'
    }

    if (-not $script:Npm) {
        throw 'npm was not found. Verify that npm is installed and available on PATH.'
    }

    if (-not $script:Go) {
        throw 'Go was not found. Install Go and reopen PowerShell before running this installer.'
    }

    $nodeVersion = (& $script:Node.Source --version 2>&1 | Out-String).Trim()
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($nodeVersion)) {
        throw 'Unable to determine the Node.js version.'
    }

    $npmVersion = (& $script:Npm.Source --version 2>&1 | Out-String).Trim()
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($npmVersion)) {
        throw 'Unable to determine the npm version.'
    }

    $goOutput = & $script:Go.Source version 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw 'Unable to determine the installed Go version.'
    }

    $goVersion = "$($goOutput | Select-Object -First 1)"
    if ($goVersion -notmatch '^go version go\d+\.\d+') {
        throw "Unexpected Go version response: $goVersion"
    }

    Write-Status PASS "Node.js: $nodeVersion"
    Write-Status PASS "npm: $npmVersion"
    Write-Status PASS "Go: $goVersion"
}

# ---------------------------------------------------------------------------
# PATH helpers
# ---------------------------------------------------------------------------

function Test-PathEntry {
    param(
        [AllowEmptyString()]
        [string]$PathValue,

        [Parameter(Mandatory)]
        [string]$Entry
    )

    if ([string]::IsNullOrWhiteSpace($PathValue)) {
        return $false
    }

    $expected = $Entry.Trim().TrimEnd('\', '/')

    foreach ($currentEntry in ($PathValue -split ';')) {
        if ([string]::IsNullOrWhiteSpace($currentEntry)) {
            continue
        }

        $current = $currentEntry.Trim().TrimEnd('\', '/')

        if ([string]::Equals(
            $current,
            $expected,
            [StringComparison]::OrdinalIgnoreCase
        )) {
            return $true
        }
    }

    return $false
}

function Add-UserPathEntry {
    param(
        [Parameter(Mandatory)]
        [string]$Entry,

        [Parameter(Mandatory)]
        [string]$Description
    )

    $userPath = [Environment]::GetEnvironmentVariable(
        'Path',
        [EnvironmentVariableTarget]::User
    )

    if (-not (Test-PathEntry -PathValue $userPath -Entry $Entry)) {
        $userEntries = @(
            $userPath -split ';' |
                Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        )

        $newUserPath = (@($Entry) + $userEntries) -join ';'

        [Environment]::SetEnvironmentVariable(
            'Path',
            $newUserPath,
            [EnvironmentVariableTarget]::User
        )

        Write-Status UPDATE "Added $Description to the user PATH."
    }
    else {
        Write-Status SKIP "$Description is already in the user PATH."
    }

    if (-not (Test-PathEntry -PathValue $env:PATH -Entry $Entry)) {
        $env:PATH = "$Entry;$env:PATH"
        Write-Status PASS "Added $Description to the current session PATH."
    }
}

# ---------------------------------------------------------------------------
# npm global installation
# ---------------------------------------------------------------------------

function Get-NpmGlobalPrefix {
    $prefix = (& $script:Npm.Source prefix --global 2>&1 | Out-String).Trim()

    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($prefix)) {
        throw 'Unable to determine the npm global prefix.'
    }

    if (-not (Test-Path -LiteralPath $prefix -PathType Container)) {
        throw "The npm global prefix does not exist: $prefix"
    }

    return $prefix
}

function Test-SqlFormatterPackage {
    $null = & $script:Npm.Source list --global $script:SqlFormatterSpec --depth=0 2>&1
    return $LASTEXITCODE -eq 0
}

function Install-SqlFormatter {
    if ((Test-SqlFormatterPackage) -and -not $Force) {
        Write-Status SKIP "$($script:SqlFormatterSpec) is already installed."
        return
    }

    if ($Force) {
        Write-Status UPDATE "Removing the existing global $($script:SqlFormatterPackage) package."

        $null = & $script:Npm.Source uninstall --global $script:SqlFormatterPackage 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Unable to remove the existing global $($script:SqlFormatterPackage) installation."
        }
    }

    Write-Status INSTALL "Installing $($script:SqlFormatterSpec) globally."

    & $script:Npm.Source install --global $script:SqlFormatterSpec
    if ($LASTEXITCODE -ne 0) {
        throw "npm failed to install $($script:SqlFormatterSpec)."
    }

    if (-not (Test-SqlFormatterPackage)) {
        throw "npm did not report the expected global package version: $($script:SqlFormatterSpec)."
    }

    Write-Status PASS "Installed $($script:SqlFormatterSpec)."
}

function Test-SqlFormatterCommand {
    $application = Get-Application -Names @($script:SqlFormatterCommand, "$($script:SqlFormatterCommand).cmd")

    if (-not $application) {
        throw "$($script:SqlFormatterCommand) was not found after installation."
    }

    $actualVersion = (& $application.Source --version 2>&1 | Out-String).Trim()
    if ($LASTEXITCODE -ne 0) {
        throw "Unable to execute $($script:SqlFormatterCommand) --version."
    }

    if ($actualVersion -ne $script:SqlFormatterVersion) {
        throw "Unexpected SQL Formatter version. Expected $($script:SqlFormatterVersion), found '$actualVersion'."
    }

    Write-Status PASS "SQL Formatter version: $actualVersion"
}

# ---------------------------------------------------------------------------
# Go binary directory and SQLS installation
# ---------------------------------------------------------------------------

function Get-GoBin {
    $gobin = (& $script:Go.Source env GOBIN 2>&1 | Out-String).Trim()

    if ($LASTEXITCODE -ne 0) {
        throw 'Unable to determine GOBIN.'
    }

    if (-not [string]::IsNullOrWhiteSpace($gobin)) {
        return $gobin
    }

    $gopath = (& $script:Go.Source env GOPATH 2>&1 | Out-String).Trim()
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($gopath)) {
        throw 'Unable to determine GOPATH.'
    }

    $firstGopath = ($gopath -split ';' | Select-Object -First 1).Trim()
    if ([string]::IsNullOrWhiteSpace($firstGopath)) {
        throw 'Go returned an empty GOPATH.'
    }

    return Join-Path $firstGopath 'bin'
}

function Get-SqlsVersion {
    param(
        [Parameter(Mandatory)]
        [string]$Executable
    )

    if (-not (Test-Path -LiteralPath $Executable -PathType Leaf)) {
        return $null
    }

    $output = & $Executable --version 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw 'SQLS executable failed its version check.'
    }

    $versionOutput = $output -join "`n"
    if ($versionOutput -notmatch '(?i)\bVersion:\s*v?(\d+\.\d+\.\d+)\b') {
        throw "Could not parse the SQLS version response: $versionOutput"
    }

    return $Matches[1]
}

function Test-SqlsVersion {
    param(
        [Parameter(Mandatory)]
        [string]$Executable
    )

    $version = Get-SqlsVersion -Executable $Executable
    if (-not $version) {
        throw 'SQLS executable was not found in the Go binary directory.'
    }

    if ($version -ne $script:SqlsVersion) {
        throw "SQLS version mismatch. Expected $($script:SqlsVersion), received $version."
    }

    Write-Status PASS "SQLS version: $version"
}

function Install-Sqls {
    param(
        [Parameter(Mandatory)]
        [string]$Executable
    )

    $installedVersion = Get-SqlsVersion -Executable $Executable

    if ($installedVersion -eq $script:SqlsVersion -and -not $Force) {
        Write-Status SKIP "SQLS $($script:SqlsVersion) is already installed."
        return
    }

    if ($installedVersion) {
        Write-Status UPDATE "Replacing SQLS $installedVersion with version $($script:SqlsVersion)."
    }
    elseif ($Force) {
        Write-Status UPDATE 'Force requested; reinstalling the pinned SQLS version.'
    }
    else {
        Write-Status INSTALL "Installing SQLS $($script:SqlsVersion)."
    }

    & $script:Go.Source install $script:SqlsPackage
    if ($LASTEXITCODE -ne 0) {
        throw "Go failed to install $($script:SqlsPackage)."
    }

    Test-SqlsVersion -Executable $Executable
    Write-Status PASS "Installed SQLS $($script:SqlsVersion)."
}

function Test-SqlsCommand {
    param(
        [Parameter(Mandatory)]
        [string]$ExpectedPath
    )

    $command = Get-Application -Names @('sqls.exe', 'sqls')
    if (-not $command) {
        throw 'SQLS is installed, but its executable is not discoverable on PATH.'
    }

    $actualPath = [System.IO.Path]::GetFullPath($command.Source)
    $expected = [System.IO.Path]::GetFullPath($ExpectedPath)

    if (-not [string]::Equals(
        $actualPath,
        $expected,
        [StringComparison]::OrdinalIgnoreCase
    )) {
        throw "SQLS resolves to an unexpected executable. Expected '$expected', received '$actualPath'."
    }

    Write-Status PASS "SQLS command resolves correctly: $actualPath"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

try {
    Write-Host ''
    Write-Status INFO 'Starting SQL Formatter and SQLS installation.'

    Test-Platform
    Test-Prerequisites

    # npm global tools
    $npmPrefix = Get-NpmGlobalPrefix
    Write-Status INFO "npm global prefix: $npmPrefix"
    Add-UserPathEntry -Entry $npmPrefix -Description 'npm global prefix'

    Install-SqlFormatter
    Test-SqlFormatterCommand

    # Go-installed tools
    $goBin = Get-GoBin
    if (-not (Test-Path -LiteralPath $goBin -PathType Container)) {
        New-Item -ItemType Directory -Path $goBin -Force | Out-Null
    }

    Add-UserPathEntry -Entry $goBin -Description 'Go binary directory'

    $sqlsPath = Join-Path $goBin $script:SqlsExecutable
    Install-Sqls -Executable $sqlsPath
    Test-SqlsCommand -ExpectedPath $sqlsPath
    Test-SqlsVersion -Executable $sqlsPath

    Write-Host ''
    Write-Status PASS 'SQL Formatter and SQLS installation and verification completed.'
    Write-Host ''
    exit 0
}
catch {
    Write-Status FAIL $_.Exception.Message
    exit 1
}
