# Install and verify the Rust toolchain used by nvim-config.
#
# Usage:
#   .\scripts\core\windows\rust.ps1
#   .\scripts\core\windows\rust.ps1 -Check
#   .\scripts\core\windows\rust.ps1 -Update
#
# Requirements:
#   - Windows
#   - PowerShell 7+
#   - Rustup
#
# Installation policy:
#   - Uses the stable Windows MSVC toolchain.
#   - Installs missing Rust components through Rustup.
#   - Does not change the default Rust toolchain.
#   - Does not install Visual Studio Build Tools or the Windows SDK.
#   - Does not persistently modify PATH.
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

$Toolchain = 'stable-x86_64-pc-windows-msvc'
$Target = 'x86_64-pc-windows-msvc'

$RequiredComponents = @(
    'rust-analyzer'
    'rustfmt'
    'rust-src'
    'clippy'
    'rust-docs'
)

$RequiredCommands = @(
    'rustc'
    'cargo'
    'rust-analyzer'
    'rustfmt'
)

$CargoBin = Join-Path $HOME '.cargo\bin'

$ProgramFilesX86 = ${env:ProgramFiles(x86)}

if ([string]::IsNullOrWhiteSpace($ProgramFilesX86)) {
    throw 'The ProgramFiles(x86) environment variable is unavailable.'
}

$VsWhere = Join-Path $ProgramFilesX86 `
    'Microsoft Visual Studio\Installer\vswhere.exe'

$VisualStudioRoot = Join-Path $ProgramFilesX86 `
    'Microsoft Visual Studio'

$WindowsSdkRoot = Join-Path $ProgramFilesX86 `
    'Windows Kits\10'

$script:Failed = $false

# ---------------------------------------------------------------------------
# Status reporting
# ---------------------------------------------------------------------------

function Write-Status {
    param(
        [ValidateSet('INFO', 'PASS', 'SKIP', 'WARN', 'FAIL')]
        [string]$Status,

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
    param([string]$Message)

    $script:Failed = $true
    Write-Status -Status FAIL -Message $Message
}

# ---------------------------------------------------------------------------
# Platform and command discovery
# ---------------------------------------------------------------------------

function Test-Windows {
    if ($env:OS -ne 'Windows_NT') {
        throw 'This installer supports Windows only.'
    }

    Write-Status -Status PASS -Message 'Windows platform detected.'
}

function Update-ProcessPath {
    $machinePath = [Environment]::GetEnvironmentVariable(
        'Path',
        [EnvironmentVariableTarget]::Machine
    )

    $userPath = [Environment]::GetEnvironmentVariable(
        'Path',
        [EnvironmentVariableTarget]::User
    )

    $entries = [System.Collections.Generic.List[string]]::new()
    $seen = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::OrdinalIgnoreCase
    )

    $pathSources = @(
        $machinePath
        $userPath
        $env:Path
        $CargoBin
    )

    foreach ($source in $pathSources) {
        if ([string]::IsNullOrWhiteSpace($source)) {
            continue
        }

        foreach ($entry in ($source -split ';')) {
            $pathEntry = $entry.Trim()

            if ([string]::IsNullOrWhiteSpace($pathEntry)) {
                continue
            }

            if ($seen.Add($pathEntry)) {
                $entries.Add($pathEntry)
            }
        }
    }

    $env:Path = $entries -join ';'

    Write-Status INFO 'Process PATH refreshed without persistent changes.'
}

function Get-Application {
    param([string]$Name)

    return Get-Command `
        -Name $Name `
        -CommandType Application `
        -ErrorAction SilentlyContinue |
        Select-Object -First 1
}

function Test-Application {
    param([string]$Name)

    $command = Get-Application -Name $Name

    if (-not $command) {
        Write-Failure "$Name is not available through PATH."
        return $null
    }

    Write-Status PASS "$Name found: $($command.Source)"

    return $command
}

# ---------------------------------------------------------------------------
# Rustup
# ---------------------------------------------------------------------------

function Invoke-Rustup {
    param([string[]]$Arguments)

    & rustup @Arguments

    if ($LASTEXITCODE -ne 0) {
        throw "Rustup command failed: rustup $($Arguments -join ' ')"
    }
}

function Test-Rustup {
    $command = Get-Application -Name 'rustup'

    if (-not $command) {
        throw 'Rustup is missing. Install it from https://rustup.rs/ and rerun this script.'
    }

    Write-Status PASS "Rustup found: $($command.Source)"

    $version = & rustup --version

    if ($LASTEXITCODE -ne 0) {
        throw 'Rustup version verification failed.'
    }

    Write-Status PASS (($version | Out-String).Trim())
}

function Test-ToolchainInstalled {
    $toolchains = & rustup toolchain list

    if ($LASTEXITCODE -ne 0) {
        throw 'Unable to list installed Rust toolchains.'
    }

    foreach ($line in $toolchains) {
        $name = ($line -split '\s+')[0]

        if ($name -eq $Toolchain) {
            return $true
        }
    }

    return $false
}

function Install-Toolchain {
    if (Test-ToolchainInstalled) {
        Write-Status SKIP "$Toolchain is already installed."
        return
    }

    Write-Status INFO "Installing $Toolchain..."

    Invoke-Rustup -Arguments @(
        'toolchain'
        'install'
        $Toolchain
        '--profile'
        'default'
    )

    if (-not (Test-ToolchainInstalled)) {
        throw "Toolchain installation could not be verified: $Toolchain"
    }

    Write-Status PASS "$Toolchain installed."
}

function Update-Toolchain {
    Write-Status INFO "Updating $Toolchain..."

    Invoke-Rustup -Arguments @(
        'update'
        $Toolchain
    )

    Write-Status PASS "$Toolchain updated."
}

# ---------------------------------------------------------------------------
# Rust components
# ---------------------------------------------------------------------------

function Get-InstalledComponents {
    $components = & rustup component list `
        --toolchain $Toolchain `
        --installed

    if ($LASTEXITCODE -ne 0) {
        throw "Unable to list installed components for $Toolchain."
    }

    return @(
        $components |
            ForEach-Object { $_.Trim() } |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    )
}

function Test-ComponentInstalled {
    param(
        [string[]]$Installed,
        [string]$Component
    )

    $expectedNames = @(
        $Component
        "$Component-$Target"
    )

    foreach ($entry in $Installed) {
        if ($entry -in $expectedNames) {
            return $true
        }
    }

    return $false
}

function Install-Components {
    $installed = Get-InstalledComponents

    foreach ($component in $RequiredComponents) {
        if (Test-ComponentInstalled `
            -Installed $installed `
            -Component $component) {

            Write-Status SKIP "$component is already installed."
            continue
        }

        Write-Status INFO "Installing Rust component: $component"

        Invoke-Rustup -Arguments @(
            'component'
            'add'
            $component
            '--toolchain'
            $Toolchain
        )

        Write-Status PASS "$component installed."

        # Refresh the installed component list after installation.
        $installed = Get-InstalledComponents
    }
}

function Test-Components {
    $installed = Get-InstalledComponents

    foreach ($component in $RequiredComponents) {
        if (Test-ComponentInstalled `
            -Installed $installed `
            -Component $component) {

            Write-Status PASS "$component is installed."
        }
        else {
            Write-Failure "$component is missing from $Toolchain."
        }
    }
}

# ---------------------------------------------------------------------------
# Rust executable verification
# ---------------------------------------------------------------------------

function Test-RustCommands {
    foreach ($name in $RequiredCommands) {
        $command = Test-Application -Name $name

        if (-not $command) {
            continue
        }

        $version = & rustup run $Toolchain $name --version

        if ($LASTEXITCODE -ne 0) {
            Write-Failure "$name failed its version check."
            continue
        }

        Write-Status PASS (
            "$name`: " + ($version | Out-String).Trim()
        )
    }

    $active = & rustup show active-toolchain

    if ($LASTEXITCODE -ne 0) {
        Write-Failure 'Unable to determine the active Rust toolchain.'
        return
    }

    $activeName = ($active -split '\s+')[0]

    if ($activeName -eq $Toolchain) {
        Write-Status PASS "Active toolchain: $active"
    }
    else {
        Write-Status WARN (
            "Active toolchain is '$activeName', not '$Toolchain'. " +
            'The installer will not change the default toolchain.'
        )
    }
}

# ---------------------------------------------------------------------------
# Visual Studio and MSVC detection
# ---------------------------------------------------------------------------

function Get-VisualStudioInstallations {
    if (Test-Path -LiteralPath $VsWhere -PathType Leaf) {
        $installations = & $VsWhere `
            -all `
            -products '*' `
            -property installationPath

        if ($LASTEXITCODE -eq 0) {
            return @(
                $installations |
                    Where-Object {
                        $_ -and (Test-Path -LiteralPath $_ -PathType Container)
                    }
            )
        }

        Write-Status WARN 'vswhere.exe could not enumerate Visual Studio installations.'
    }

    if (-not (Test-Path -LiteralPath $VisualStudioRoot -PathType Container)) {
        return @()
    }

    return @(
        Get-ChildItem -LiteralPath $VisualStudioRoot -Directory |
            ForEach-Object {
                Get-ChildItem `
                    -LiteralPath $_.FullName `
                    -Directory `
                    -ErrorAction SilentlyContinue
            } |
            Select-Object -ExpandProperty FullName
    )
}

function Get-MSVCBinaries {
    param(
        [string[]]$Installations,
        [ValidateSet('cl.exe', 'link.exe')]
        [string]$Name
    )

    $binaries = @()

    foreach ($installation in $Installations) {
        $msvcRoot = Join-Path $installation 'VC\Tools\MSVC'

        if (-not (Test-Path -LiteralPath $msvcRoot -PathType Container)) {
            continue
        }

        $versions = Get-ChildItem `
            -LiteralPath $msvcRoot `
            -Directory `
            -ErrorAction SilentlyContinue

        foreach ($version in $versions) {
            $binary = Join-Path $version.FullName `
                "bin\Hostx64\x64\$Name"

            if (Test-Path -LiteralPath $binary -PathType Leaf) {
                $binaries += Get-Item -LiteralPath $binary
            }
        }
    }

    return $binaries
}

function Test-MSVC {
    Write-Host ''
    Write-Status INFO 'Checking MSVC compiler and linker...'

    $installations = @(Get-VisualStudioInstallations)

    $compilers = @(
        Get-MSVCBinaries -Installations $installations -Name 'cl.exe'
    )

    $linkers = @(
        Get-MSVCBinaries -Installations $installations -Name 'link.exe'
    )

    if ($compilers.Count -gt 0) {
        Write-Status PASS (
            "MSVC compiler found on disk: $($compilers[0].FullName)"
        )
    }
    else {
        Write-Failure 'MSVC x64 compiler was not found on disk.'
    }

    if ($linkers.Count -gt 0) {
        Write-Status PASS (
            "MSVC linker found on disk: $($linkers[0].FullName)"
        )
    }
    else {
        Write-Failure 'MSVC x64 linker was not found on disk.'
    }

    if (Test-Path -LiteralPath $VsWhere -PathType Leaf) {
        $workload = & $VsWhere `
            -latest `
            -products '*' `
            -requires Microsoft.VisualStudio.Workload.VCTools `
            -property installationPath

        if ($LASTEXITCODE -eq 0 -and $workload) {
            Write-Status PASS 'Visual C++ workload detected by vswhere.'
        }
        else {
            Write-Status WARN (
                'The Visual C++ workload was not confirmed by vswhere. ' +
                'Individual compiler and linker files are checked separately.'
            )
        }
    }
    else {
        Write-Status WARN 'vswhere.exe is unavailable.'
    }

    if (Get-Application -Name 'cl.exe') {
        Write-Status PASS 'cl.exe is discoverable through the current PATH.'
    }
    else {
        Write-Status WARN (
            'cl.exe exists on disk but is not discoverable through PATH.'
        )
    }

    if (Get-Application -Name 'link.exe') {
        Write-Status PASS 'link.exe is discoverable through the current PATH.'
    }
    else {
        Write-Status WARN (
            'link.exe exists on disk but is not discoverable through PATH.'
        )
    }
}

# ---------------------------------------------------------------------------
# Windows SDK detection
# ---------------------------------------------------------------------------

function Test-WindowsSdk {
    Write-Host ''
    Write-Status INFO 'Checking Windows SDK...'

    $includeRoot = Join-Path $WindowsSdkRoot 'Include'
    $libRoot = Join-Path $WindowsSdkRoot 'Lib'

    if (-not (Test-Path -LiteralPath $includeRoot -PathType Container)) {
        Write-Failure "Windows SDK Include directory is missing: $includeRoot"
        return
    }

    if (-not (Test-Path -LiteralPath $libRoot -PathType Container)) {
        Write-Failure "Windows SDK Lib directory is missing: $libRoot"
        return
    }

    $includeVersions = @(
        Get-ChildItem -LiteralPath $includeRoot -Directory |
            Select-Object -ExpandProperty Name
    )

    $libVersions = @(
        Get-ChildItem -LiteralPath $libRoot -Directory |
            Select-Object -ExpandProperty Name
    )

    $matchingVersions = @(
        $includeVersions |
            Where-Object { $libVersions -contains $_ }
    )

    if ($matchingVersions.Count -eq 0) {
        Write-Failure 'No matching Windows SDK Include and Lib versions were found.'
        return
    }

    foreach ($version in $matchingVersions) {
        Write-Status PASS "Windows SDK $version found."
    }
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

try {
    if ($Check -and $Update) {
        throw 'Use either -Check or -Update, not both.'
    }

    Write-Host ''
    Write-Status INFO 'Preparing Rust dependencies for nvim-config...'

    Test-Windows

    Update-ProcessPath

    Test-Rustup

    if ($Check) {
        Write-Status INFO 'Check mode: installation is disabled.'
    }
    else {
        # Ensure the requested toolchain exists before updating it.
        Install-Toolchain

        if ($Update) {
            Update-Toolchain
        }

        Install-Components
    }

    Test-Components
    Test-RustCommands

    Test-MSVC
    Test-WindowsSdk

    Write-Host ''

    if ($script:Failed) {
        Write-Status FAIL (
            'Rust dependency verification completed with failures.'
        )

        exit 1
    }

    Write-Status PASS (
        'Rust dependency installation and verification completed.'
    )

    exit 0
}
catch {
    Write-Status FAIL $_.Exception.Message
    exit 1
}

