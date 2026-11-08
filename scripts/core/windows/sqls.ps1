# Install and verify SQLS, the SQL language server used by nvim-config.
#
# Usage:
#   .\scripts\core\windows\sqls.ps1
#   .\scripts\core\windows\sqls.ps1 -Force
#
# Requirements:
#   - Windows
#   - PowerShell 7+
#   - Go
#
# Installation policy:
#   - Installs the pinned SQLS version through go install.
#   - Respects GOBIN and GOPATH.
#   - Adds the Go binary directory to the user PATH when necessary.
#   - Does not install Go.
#   - Does not configure database connections.
#   - Does not run automatically during Neovim startup.

[CmdletBinding()]
param(
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

$SqlsModule = 'github.com/sqls-server/sqls'
$SqlsVersion = '0.2.48'
$SqlsPackage = "$SqlsModule@v$SqlsVersion"
$SqlsExecutable = 'sqls.exe'

# ---------------------------------------------------------------------------
# Status reporting
# ---------------------------------------------------------------------------

function Write-Status {
    param(
        [ValidateSet('INFO', 'PASS', 'SKIP', 'INSTALL', 'UPDATE', 'FAIL')]
        [string]$Status,

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
# Command discovery
# ---------------------------------------------------------------------------

function Get-Application {
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    return Get-Command `
        -Name $Name `
        -CommandType Application `
        -ErrorAction SilentlyContinue |
        Select-Object -First 1
}

function Test-Windows {
    if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
        throw 'This installer supports Windows only.'
    }

    Write-Status PASS 'Windows platform detected.'
}

# ---------------------------------------------------------------------------
# Go prerequisites
# ---------------------------------------------------------------------------

function Test-Go {
    $command = Get-Application -Name 'go.exe'

    if (-not $command) {
        $command = Get-Application -Name 'go'
    }

    if (-not $command) {
        throw 'Go is unavailable. Install Go and reopen PowerShell.'
    }

    $output = & $command.Source version 2>&1

    if ($LASTEXITCODE -ne 0) {
        throw 'Unable to determine the installed Go version.'
    }

    $version = "$($output | Select-Object -First 1)"

    if ($version -notmatch '^go version go\d+\.\d+') {
        throw "Unexpected Go version response: $version"
    }

    Write-Status PASS "Go is available: $version"

    return $command
}

# ---------------------------------------------------------------------------
# Go binary directory
# ---------------------------------------------------------------------------

function Get-GoBin {
    param(
        [Parameter(Mandatory)]
        [string]$GoExecutable
    )

    $gobin = & $GoExecutable env GOBIN 2>&1

    if ($LASTEXITCODE -ne 0) {
        throw 'Unable to determine GOBIN.'
    }

    $gobin = "$gobin".Trim()

    if (-not [string]::IsNullOrWhiteSpace($gobin)) {
        return $gobin
    }

    $gopath = & $GoExecutable env GOPATH 2>&1

    if ($LASTEXITCODE -ne 0) {
        throw 'Unable to determine GOPATH.'
    }

    $firstGopath = "$gopath".Trim() -split ';' |
        Select-Object -First 1

    if ([string]::IsNullOrWhiteSpace($firstGopath)) {
        throw 'Go returned an empty GOPATH.'
    }

    return Join-Path $firstGopath 'bin'
}

# ---------------------------------------------------------------------------
# PATH management
# ---------------------------------------------------------------------------

function Test-PathEntry {
    param(
        [AllowEmptyString()]
        [string]$PathValue,

        [Parameter(Mandatory)]
        [string]$Entry
    )

    foreach ($currentEntry in ($PathValue -split ';')) {
        $current = $currentEntry.Trim().TrimEnd('\')
        $expected = $Entry.Trim().TrimEnd('\')

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

function Add-GoBinToPath {
    param(
        [Parameter(Mandatory)]
        [string]$GoBin
    )

    if (-not (Test-Path -LiteralPath $GoBin -PathType Container)) {
        New-Item -ItemType Directory -Path $GoBin -Force |
            Out-Null
    }

    # Persist the Go binary directory in the user PATH.
    $userPath = [Environment]::GetEnvironmentVariable(
        'Path',
        [EnvironmentVariableTarget]::User
    )

    if (-not (Test-PathEntry -PathValue $userPath -Entry $GoBin)) {
        Write-Status UPDATE 'Adding the Go binary directory to the user PATH.'

        $userEntries = @(
            $userPath -split ';' |
                Where-Object {
                    -not [string]::IsNullOrWhiteSpace($_)
                }
        )

        $newUserPath = (@($GoBin) + $userEntries) -join ';'

        [Environment]::SetEnvironmentVariable(
            'Path',
            $newUserPath,
            [EnvironmentVariableTarget]::User
        )
    }

    # Make SQLS discoverable in this PowerShell process.
    if (-not (Test-PathEntry -PathValue $env:PATH -Entry $GoBin)) {
        $env:PATH = "$GoBin;$env:PATH"
    }

    Write-Status PASS "Go binary directory is available on PATH: $GoBin"
}

# ---------------------------------------------------------------------------
# SQLS version verification
# ---------------------------------------------------------------------------

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

    if ($version -ne $SqlsVersion) {
        throw "SQLS version mismatch. Expected $SqlsVersion, received $version."
    }

    Write-Status PASS "SQLS executable reports version $version."
}

# ---------------------------------------------------------------------------
# Installation
# ---------------------------------------------------------------------------

function Install-Sqls {
    param(
        [Parameter(Mandatory)]
        [string]$GoExecutable,

        [Parameter(Mandatory)]
        [string]$Executable
    )

    $installedVersion = Get-SqlsVersion -Executable $Executable

    if ($installedVersion -eq $SqlsVersion -and -not $Force) {
        Write-Status SKIP "SQLS $SqlsVersion is already installed."
        return
    }

    if ($installedVersion -and $installedVersion -ne $SqlsVersion) {
        Write-Status UPDATE (
            "Replacing SQLS $installedVersion with version $SqlsVersion."
        )
    }
    elseif ($Force) {
        Write-Status UPDATE 'Force requested; reinstalling the pinned SQLS version.'
    }
    else {
        Write-Status INSTALL "Installing SQLS $SqlsVersion."
    }

    & $GoExecutable install $SqlsPackage

    if ($LASTEXITCODE -ne 0) {
        throw "Go failed to install $SqlsPackage."
    }

    Test-SqlsVersion -Executable $Executable

    Write-Status PASS "SQLS $SqlsVersion installed and verified."
}

# ---------------------------------------------------------------------------
# Executable discovery
# ---------------------------------------------------------------------------

function Test-SqlsCommand {
    param(
        [Parameter(Mandatory)]
        [string]$ExpectedPath
    )

    $command = Get-Application -Name 'sqls.exe'

    if (-not $command) {
        $command = Get-Application -Name 'sqls'
    }

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
        throw (
            "SQLS resolves to an unexpected executable. " +
            "Expected '$expected', received '$actualPath'."
        )
    }

    Write-Status PASS "SQLS command resolves correctly: $actualPath"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

try {
    Write-Host ''
    Write-Status INFO 'Starting SQLS installation.'

    Test-Windows

    $go = Test-Go
    $goBin = Get-GoBin -GoExecutable $go.Source

    Add-GoBinToPath -GoBin $goBin

    $sqlsPath = Join-Path $goBin $SqlsExecutable

    Install-Sqls `
        -GoExecutable $go.Source `
        -Executable $sqlsPath

    Test-SqlsCommand -ExpectedPath $sqlsPath
    Test-SqlsVersion -Executable $sqlsPath

    Write-Host ''
    Write-Status PASS 'SQLS installation and verification completed.'
    Write-Host ''
}
catch {
    Write-Status FAIL $_.Exception.Message
    exit 1
}
