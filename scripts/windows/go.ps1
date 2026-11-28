# Install and verify the Go tooling used by nvim-config.
#
# Usage:
#   .\go.ps1
#   .\go.ps1 -Check
#   .\go.ps1 -Update
#
# Required tools:
#   - Go toolchain (go and gofmt)
#   - gopls
#   - golangci-lint
#
# Installation policy:
#   - Installs Go with WinGet when it is missing.
#   - -Update also asks WinGet to upgrade Go.
#   - Installs gopls with the official Go installation command.
#   - Installs/updates golangci-lint with WinGet.
#   - Adds Go and Go tool binary directories to the current user's PATH.
#   - Does not install Delve or configure debugging.
#   - Does not run automatically during Neovim startup.

[CmdletBinding()]
param(
    [switch]$Check,
    [switch]$Update
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

$GoPackageId = 'GoLang.Go'
$GoplsModule = 'golang.org/x/tools/gopls@latest'
$GolangciLintPackageId = 'GolangCI.golangci-lint'

$script:GoBin = $null
$script:GoInstallBin = Join-Path $env:ProgramFiles 'Go\bin'
$script:Failed = $false

# ---------------------------------------------------------------------------
# Status reporting
# ---------------------------------------------------------------------------

function Write-Status {
    param(
        [ValidateSet('INFO', 'PASS', 'SKIP', 'WARN', 'FAIL')]
        [string]$Status,

        [Parameter(Mandatory)]
        [string]$Message
    )

    $color = switch ($Status) {
        'INFO' { 'Cyan' }
        'PASS' { 'Green' }
        'SKIP' { 'DarkGray' }
        'WARN' { 'Yellow' }
        'FAIL' { 'Red' }
    }

    Write-Host "[$Status] $Message" -ForegroundColor $color
}

function Write-Failure {
    param([Parameter(Mandatory)][string]$Message)

    $script:Failed = $true
    Write-Status -Status FAIL -Message $Message
}

# ---------------------------------------------------------------------------
# Platform and command discovery
# ---------------------------------------------------------------------------

function Test-Platform {
    if ($env:OS -ne 'Windows_NT') {
        throw 'This script supports Windows only.'
    }

    if ($PSVersionTable.PSVersion.Major -lt 7) {
        throw 'PowerShell 7 or later is required.'
    }

    Write-Status PASS "Windows and PowerShell $($PSVersionTable.PSVersion) detected."
}

function Get-Application {
    param([Parameter(Mandatory)][string]$Name)

    return Get-Command `
        -Name $Name `
        -CommandType Application `
        -ErrorAction SilentlyContinue |
        Select-Object -First 1
}

function Invoke-Tool {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string[]]$Arguments
    )

    $command = Get-Application -Name $Name

    if (-not $command) {
        throw "Required executable not found: $Name"
    }

    $output = @(& $command.Source @Arguments 2>&1)
    $exitCode = $LASTEXITCODE

    if ($exitCode -ne 0) {
        $details = ($output | ForEach-Object { "$_".Trim() } |
                Where-Object { $_ }) -join [Environment]::NewLine

        throw "$Name $($Arguments -join ' ') failed with exit code $exitCode. $details"
    }

    return (($output | ForEach-Object { "$_".Trim() } |
                Where-Object { $_ }) -join ' ')
}

# ---------------------------------------------------------------------------
# PATH handling
# ---------------------------------------------------------------------------

function Add-UserPath {
    param([Parameter(Mandatory)][string]$Directory)

    if (-not (Test-Path -LiteralPath $Directory -PathType Container)) {
        throw "Cannot add a missing directory to PATH: $Directory"
    }

    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $entries = @(
        $userPath -split ';' |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    )

    $exists = $entries | Where-Object {
        [string]::Equals(
            $_.Trim().TrimEnd('\'),
            $Directory.Trim().TrimEnd('\'),
            [StringComparison]::OrdinalIgnoreCase
        )
    }

    if (-not $exists) {
        $entries += $Directory

        [Environment]::SetEnvironmentVariable(
            'Path',
            ($entries -join ';'),
            [EnvironmentVariableTarget]::User
        )

        Write-Status PASS "Added directory to the user PATH: $Directory"
    }
    else {
        Write-Status SKIP "Directory is already in the user PATH: $Directory"
    }
}

function Update-ProcessPath {
    $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')

    $sources = @(
        $machinePath
        $userPath
        $env:Path
        $script:GoInstallBin
        $script:GoBin
    )

    $entries = [System.Collections.Generic.List[string]]::new()
    $seen = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::OrdinalIgnoreCase
    )

    foreach ($source in $sources) {
        if ([string]::IsNullOrWhiteSpace($source)) {
            continue
        }

        foreach ($entry in ($source -split ';')) {
            $value = $entry.Trim()

            if ($value -and $seen.Add($value)) {
                $entries.Add($value)
            }
        }
    }

    $env:Path = $entries -join ';'
    Write-Status INFO 'Process PATH refreshed.'
}

# ---------------------------------------------------------------------------
# WinGet package management
# ---------------------------------------------------------------------------

function Invoke-WinGetPackage {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('install', 'upgrade')]
        [string]$Operation,

        [Parameter(Mandatory)]
        [string]$PackageId
    )

    $winget = Get-Application -Name 'winget'
    if (-not $winget) {
        throw "WinGet is required to $Operation $PackageId. Install Microsoft App Installer, then rerun this script."
    }

    $arguments = @(
        $Operation
        '--exact'
        '--id'
        $PackageId
        '--source'
        'winget'
        '--accept-package-agreements'
        '--accept-source-agreements'
        '--disable-interactivity'
    )

    if ($Operation -eq 'install') {
        $arguments += '--silent'
    }

    Write-Status INFO "$Operation $PackageId with WinGet..."
    & $winget.Source @arguments
    $exitCode = $LASTEXITCODE

    if ($exitCode -ne 0) {
        throw "WinGet $Operation for $PackageId failed with exit code $exitCode."
    }
}

# ---------------------------------------------------------------------------
# Go toolchain
# ---------------------------------------------------------------------------

function Initialize-GoEnvironment {
    Update-ProcessPath

    $go = Get-Application -Name 'go'

    if (-not $go -and (Test-Path -LiteralPath (Join-Path $script:GoInstallBin 'go.exe'))) {
        $env:Path = "$script:GoInstallBin;$env:Path"
        $go = Get-Application -Name 'go'
    }

    if (-not $go) {
        if ($Check) {
            throw 'Go is missing. Check mode does not install software. Run .\go.ps1 to install Go automatically.'
        }

        Write-Status WARN 'Go is missing. Installing the Go toolchain with WinGet...'
        Invoke-WinGetPackage -Operation install -PackageId $GoPackageId
        Update-ProcessPath

        if (Test-Path -LiteralPath (Join-Path $script:GoInstallBin 'go.exe')) {
            $env:Path = "$script:GoInstallBin;$env:Path"
        }

        $go = Get-Application -Name 'go'
        if (-not $go) {
            throw 'Go installation completed, but go.exe is still not discoverable. Restart PowerShell and rerun this script.'
        }
    }
    elseif ($Update) {
        Invoke-WinGetPackage -Operation upgrade -PackageId $GoPackageId
        Update-ProcessPath

        if (Test-Path -LiteralPath (Join-Path $script:GoInstallBin 'go.exe')) {
            $env:Path = "$script:GoInstallBin;$env:Path"
        }
    }

    $go = Get-Application -Name 'go'
    if (-not $go) {
        throw 'Go is not available after refreshing PATH.'
    }

    $goVersion = Invoke-Tool -Name 'go' -Arguments @('version')
    Write-Status PASS "$goVersion ($($go.Source))"

    $gofmt = Get-Application -Name 'gofmt'
    if (-not $gofmt -and (Test-Path -LiteralPath (Join-Path $script:GoInstallBin 'gofmt.exe'))) {
        $env:Path = "$script:GoInstallBin;$env:Path"
        $gofmt = Get-Application -Name 'gofmt'
    }

    if (-not $gofmt) {
        throw 'gofmt.exe is missing. Repair or reinstall the Go toolchain.'
    }

    $gopath = Invoke-Tool -Name 'go' -Arguments @('env', 'GOPATH')
    $gobin = Invoke-Tool -Name 'go' -Arguments @('env', 'GOBIN')

    if ([string]::IsNullOrWhiteSpace($gobin)) {
        $gobin = Join-Path $gopath 'bin'
    }

    $script:GoBin = $gobin.Trim()

    if (-not (Test-Path -LiteralPath $script:GoBin -PathType Container)) {
        if ($Check) {
            throw "Go binary directory does not exist: $script:GoBin"
        }

        New-Item -ItemType Directory -Path $script:GoBin -Force | Out-Null
    }

    Update-ProcessPath
    Write-Status PASS "gofmt found: $($gofmt.Source)"
    Write-Status INFO "Go binary directory: $script:GoBin"

    if (-not $Check) {
        Add-UserPath -Directory $script:GoInstallBin
        Add-UserPath -Directory $script:GoBin
        Update-ProcessPath
    }
}

# ---------------------------------------------------------------------------
# gopls
# ---------------------------------------------------------------------------

function Get-Gopls {
    return Get-Application -Name 'gopls'
}

function Install-Gopls {
    param([switch]$Force)

    $existing = Get-Gopls

    if ($existing -and -not $Force) {
        $version = Invoke-Tool -Name 'gopls' -Arguments @('version')
        Write-Status SKIP "gopls is already available: $version"
        return
    }

    Write-Status INFO "Installing gopls from $GoplsModule..."

    $temporaryDirectory = Join-Path ([System.IO.Path]::GetTempPath()) (
        'nvim-go-install-' + [guid]::NewGuid().ToString('N')
    )

    New-Item -ItemType Directory -Path $temporaryDirectory -Force | Out-Null

    try {
        Push-Location $temporaryDirectory

        try {
            $output = @(& go install $GoplsModule 2>&1)
            $exitCode = $LASTEXITCODE

            if ($exitCode -ne 0) {
                $details = ($output | ForEach-Object { "$_".Trim() } |
                        Where-Object { $_ }) -join [Environment]::NewLine

                throw "go install failed with exit code $exitCode. $details"
            }
        }
        finally {
            Pop-Location
        }
    }
    finally {
        Remove-Item -LiteralPath $temporaryDirectory -Recurse -Force `
            -ErrorAction SilentlyContinue
    }

    Update-ProcessPath

    $installed = Get-Gopls
    if (-not $installed) {
        throw "gopls installation completed, but gopls is not discoverable. Expected it in: $script:GoBin"
    }

    $version = Invoke-Tool -Name 'gopls' -Arguments @('version')
    Write-Status PASS "gopls verified: $version"
}

# ---------------------------------------------------------------------------
# golangci-lint
# ---------------------------------------------------------------------------

function Get-GolangciLint {
    return Get-Application -Name 'golangci-lint'
}

function Install-GolangciLint {
    param([switch]$Force)

    $existing = Get-GolangciLint

    if ($existing -and -not $Force) {
        $version = Invoke-Tool -Name 'golangci-lint' -Arguments @('--version')
        Write-Status SKIP "golangci-lint is already available: $version"
        return
    }

    $operation = if ($existing) { 'upgrade' } else { 'install' }
    Invoke-WinGetPackage -Operation $operation -PackageId $GolangciLintPackageId

    Update-ProcessPath

    $installed = Get-GolangciLint
    if (-not $installed) {
        throw 'WinGet completed, but golangci-lint is not discoverable in PATH. Restart PowerShell and run -Check.'
    }

    $version = Invoke-Tool -Name 'golangci-lint' -Arguments @('--version')
    Write-Status PASS "golangci-lint verified: $version"
}

# ---------------------------------------------------------------------------
# Verification
# ---------------------------------------------------------------------------

function Test-GoDependencies {
    Write-Host ''
    Write-Status INFO 'Verifying Go dependencies...'

    $checks = @(
        @{ Name = 'go'; Arguments = @('version') }
        @{ Name = 'gopls'; Arguments = @('version') }
        @{ Name = 'golangci-lint'; Arguments = @('--version') }
    )

    foreach ($check in $checks) {
        try {
            $output = Invoke-Tool `
                -Name $check.Name `
                -Arguments $check.Arguments

            Write-Status PASS "$($check.Name): $output"
        }
        catch {
            Write-Failure $_.Exception.Message
        }
    }

    $gofmt = Get-Application -Name 'gofmt'
    if ($gofmt) {
        Write-Status PASS "gofmt found: $($gofmt.Source)"
    }
    else {
        Write-Failure 'gofmt.exe is not discoverable in PATH.'
    }

    if ($script:Failed) {
        throw 'Go dependency verification completed with failures.'
    }
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

try {
    if ($Check -and $Update) {
        throw 'Use either -Check or -Update, not both.'
    }

    Test-Platform
    Initialize-GoEnvironment

    if ($Check) {
        Write-Status INFO 'Check mode: installation and updates are disabled.'
    }
    else {
        Install-Gopls -Force:$Update
        Install-GolangciLint -Force:$Update
    }

    Test-GoDependencies

    Write-Host ''
    Write-Status PASS 'Go tooling is installed and verified.'
    Write-Status INFO 'Restart PowerShell and Neovim after installing or updating Go tooling.'
    exit 0
}
catch {
    Write-Host ''
    Write-Status FAIL $_.Exception.Message
    exit 1
}
