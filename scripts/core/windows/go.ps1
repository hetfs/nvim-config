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
#   - Requires an existing Go toolchain; does not select or upgrade Go.
#   - Installs gopls with the official Go installation command.
#   - Installs golangci-lint with WinGet.
#   - Adds the Go binary directory to the current user's PATH when needed.
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

$GoplsModule = 'golang.org/x/tools/gopls@latest'
$GolangciLintPackageId = 'GolangCI.golangci-lint'

$script:GoBin = $null
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

        Write-Status PASS "Added Go binary directory to the user PATH: $Directory"
    }
    else {
        Write-Status SKIP "Go binary directory is already in the user PATH: $Directory"
    }
}

function Update-ProcessPath {
    $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')

    $sources = @(
        $machinePath
        $userPath
        $env:Path
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
# Go toolchain
# ---------------------------------------------------------------------------

function Initialize-GoEnvironment {
    $go = Get-Application -Name 'go'

    if (-not $go) {
        throw 'Go is missing. Install and activate a Go toolchain, then rerun this script.'
    }

    $goVersion = Invoke-Tool -Name 'go' -Arguments @('version')
    Write-Status PASS $goVersion

    $gofmt = Get-Application -Name 'gofmt'

    if (-not $gofmt) {
        throw 'gofmt is missing. Verify that the Go toolchain bin directory is on PATH.'
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

        New-Item -ItemType Directory -Path $script:GoBin -Force |
            Out-Null
    }

    Update-ProcessPath
    Write-Status INFO "Go binary directory: $script:GoBin"
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

    New-Item -ItemType Directory -Path $temporaryDirectory -Force |
        Out-Null

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

    $winget = Get-Application -Name 'winget'

    if (-not $winget) {
        throw 'WinGet is required to install golangci-lint. Install App Installer or install golangci-lint manually.'
    }

    $operation = if ($existing) { 'upgrade' } else { 'install' }

    Write-Status INFO "$operation golangci-lint with WinGet..."

    $arguments = @(
        $operation
        '--exact'
        '--id'
        $GolangciLintPackageId
        '--accept-package-agreements'
        '--accept-source-agreements'
    )

    if ($operation -eq 'install') {
        $arguments += '--silent'
    }

    & $winget.Source @arguments
    $exitCode = $LASTEXITCODE

    if ($exitCode -ne 0) {
        throw "WinGet $operation failed with exit code $exitCode."
    }

    Update-ProcessPath

    $installed = Get-GolangciLint

    if (-not $installed) {
        throw 'WinGet completed, but golangci-lint is not discoverable in PATH. Open a new PowerShell session and run -Check.'
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
        @{ Name = 'gofmt'; Arguments = @('-h') }
        @{ Name = 'gopls'; Arguments = @('version') }
        @{ Name = 'golangci-lint'; Arguments = @('--version') }
    )

    foreach ($check in $checks) {
        try {
            $output = Invoke-Tool `
                -Name $check.Name `
                -Arguments $check.Arguments

            if ($check.Name -eq 'gofmt') {
                Write-Status PASS "gofmt found: $((Get-Application -Name 'gofmt').Source)"
            }
            else {
                Write-Status PASS "$($check.Name): $output"
            }
        }
        catch {
            Write-Failure $_.Exception.Message
        }
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

        # Go installs command binaries into GOBIN or GOPATH\bin.
        Add-UserPath -Directory $script:GoBin
        Update-ProcessPath
    }

    Test-GoDependencies

    Write-Host ''
    Write-Status PASS 'Go tooling is installed and verified.'
    Write-Status INFO 'Restart PowerShell and Neovim after updating gopls.'
    exit 0
}
catch {
    Write-Host ''
    Write-Status FAIL $_.Exception.Message
    exit 1
}
