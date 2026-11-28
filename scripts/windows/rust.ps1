
# ============================================================================
# Rust Toolchain Installer and MSVC x64 Environment Manager
# Project: nvim-config
# Platform: Windows x64
# Requirements: PowerShell 7+
#
# Usage:
#   .\rust.ps1
#   .\rust.ps1 -Check
#   .\rust.ps1 -Update
#
# Installation policy:
#   - Uses stable-x86_64-pc-windows-msvc.
#   - Automatically installs Rustup through WinGet when missing.
#   - Installs missing Rust components through Rustup.
#   - Detects an existing Visual Studio / Build Tools MSVC x64 installation.
#   - Installs Visual Studio Build Tools with the MSVC x64 workload when missing.
#   - Uses vswhere when available and falls back to existing compiler paths.
#   - Activates the MSVC x64 developer environment using VsDevCmd.bat.
#   - Uses the MSVC x64 compiler (cl.exe).
#   - Uses the MSVC x64 linker (link.exe).
#   - Configures Cargo and native C/C++ builds to use MSVC.
#   - Verifies the Windows SDK x64 environment.
#   - Does not install or change Visual Studio when -Check is used.
#   - Does not change the default Rust toolchain.
#   - Does not permanently modify PATH.
#   - Does not run automatically during Neovim startup.
# ============================================================================

[CmdletBinding()]
param(
    [switch]$Check,
    [switch]$Update
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ============================================================================
# Configuration
# ============================================================================

$script:Toolchain = 'stable-x86_64-pc-windows-msvc'
$script:Target = 'x86_64-pc-windows-msvc'

$script:RequiredComponents = @(
    'rust-analyzer'
    'rustfmt'
    'rust-src'
    'clippy'
    'rust-docs'
)

$script:RequiredCommands = @(
    'rustc'
    'cargo'
    'rust-analyzer'
    'rustfmt'
)

$script:Failed = $false
$script:RustupPath = $null
$script:VsInstallation = $null
$script:VsDevCmd = $null
$script:MSVCCompiler = $null
$script:MSVCLinker = $null
$script:MSVCVersion = $null
$script:WindowsSdkRoot = $null
$script:WindowsSdkVersion = $null

$script:CargoHome = if (
    -not [string]::IsNullOrWhiteSpace($env:CARGO_HOME)
) {
    $env:CARGO_HOME
}
else {
    Join-Path $HOME '.cargo'
}

$script:CargoBin = Join-Path $script:CargoHome 'bin'

$script:ProgramFilesX86 = ${env:ProgramFiles(x86)}

if ([string]::IsNullOrWhiteSpace($script:ProgramFilesX86)) {
    $script:ProgramFilesX86 = $env:ProgramFiles
}

if ([string]::IsNullOrWhiteSpace($script:ProgramFilesX86)) {
    throw 'Unable to determine the Windows Program Files directory.'
}

# Resolved at runtime because Visual Studio can be installed on a
# non-default drive or under either Program Files directory.
$script:VsWhere = $null

# ============================================================================
# Status Reporting
# ============================================================================

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

    Write-Status FAIL $Message
}

# ============================================================================
# Environment Detection
# ============================================================================

function Test-PowerShellVersion {
    if ($PSVersionTable.PSVersion.Major -lt 7) {
        throw 'PowerShell 7 or newer is required.'
    }

    Write-Status PASS (
        "PowerShell $($PSVersionTable.PSVersion) detected."
    )
}

function Test-Windows {
    if ($env:OS -ne 'Windows_NT') {
        throw 'This installer supports Windows only.'
    }

    if (-not [Environment]::Is64BitOperatingSystem) {
        throw 'This installer requires 64-bit Windows.'
    }

    Write-Status PASS 'Windows x64 platform detected.'
}

# ============================================================================
# PATH Management
# ============================================================================

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
        $script:CargoBin
    )

    foreach ($source in $pathSources) {
        if ([string]::IsNullOrWhiteSpace($source)) {
            continue
        }

        foreach ($entry in ($source -split ';')) {
            $pathEntry = $entry.Trim().Trim('"').TrimEnd('\')

            if ([string]::IsNullOrWhiteSpace($pathEntry)) {
                continue
            }

            if ($seen.Add($pathEntry)) {
                $entries.Add($pathEntry)
            }
        }
    }

    $env:Path = $entries -join ';'

    Write-Status INFO (
        'Process PATH refreshed without persistent changes.'
    )
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

# ============================================================================
# Rustup Installation and Detection
# ============================================================================

function Install-Rustup {
    Write-Status INFO 'Rustup is missing. Installing through WinGet...'

    $winget = Get-Application -Name 'winget'

    if (-not $winget) {
        throw @"
WinGet is unavailable.

Install Rustup manually:
https://rustup.rs/

Alternatively, install or repair WinGet through Microsoft Store.
"@
    }

    & $winget.Source install `
        --id Rustlang.Rustup `
        -e `
        --source winget `
        --accept-package-agreements `
        --accept-source-agreements

    if ($LASTEXITCODE -ne 0) {
        throw (
            "WinGet failed to install Rustup. Exit code: $LASTEXITCODE"
        )
    }

    Write-Status PASS 'Rustup installation completed.'

    Update-ProcessPath

    $rustupExe = Join-Path $script:CargoBin 'rustup.exe'

    if (Test-Path -LiteralPath $rustupExe -PathType Leaf) {
        $script:RustupPath = $rustupExe
    }
    else {
        $command = Get-Application -Name 'rustup'

        if ($command) {
            $script:RustupPath = $command.Source
        }
    }

    if (-not $script:RustupPath) {
        throw @"
Rustup installation completed, but rustup.exe could not be detected.

Expected location:
$rustupExe

Restart PowerShell and run this script again.
"@
    }
}

function Test-Rustup {
    param(
        [switch]$InstallIfMissing
    )

    $rustupExe = Join-Path $script:CargoBin 'rustup.exe'

    if (Test-Path -LiteralPath $rustupExe -PathType Leaf) {
        $script:RustupPath = $rustupExe
    }
    else {
        $command = Get-Application -Name 'rustup'

        if ($command) {
            $script:RustupPath = $command.Source
        }
    }

    if (-not $script:RustupPath) {
        if (-not $InstallIfMissing) {
            throw (
                'Rustup is missing. Automatic installation is disabled in Check mode.'
            )
        }

        Install-Rustup
    }

    if ($env:Path -notlike "*$script:CargoBin*") {
        $env:Path = "$script:CargoBin;$env:Path"
    }

    Write-Status PASS "Rustup found: $script:RustupPath"

    $version = & $script:RustupPath --version

    if ($LASTEXITCODE -ne 0) {
        throw 'Rustup version verification failed.'
    }

    Write-Status PASS (($version | Out-String).Trim())
}

function Invoke-Rustup {
    param(
        [Parameter(Mandatory)]
        [string[]]$Arguments
    )

    if (-not $script:RustupPath) {
        throw 'Rustup executable has not been initialized.'
    }

    & $script:RustupPath @Arguments

    if ($LASTEXITCODE -ne 0) {
        throw (
            "Rustup command failed: rustup $($Arguments -join ' ')"
        )
    }
}

# ============================================================================
# Rust Version Verification
# ============================================================================

function Test-RustVersions {
    Write-Host ''

    Write-Status INFO 'Verifying Rust installation...'

    foreach ($name in @('rustup', 'rustc', 'cargo')) {
        $executable = if ($name -eq 'rustup') {
            $script:RustupPath
        }
        else {
            $command = Get-Application -Name $name

            if ($command) {
                $command.Source
            }
            else {
                $null
            }
        }

        if (-not $executable) {
            Write-Failure "$name is not available through PATH."
            continue
        }

        $version = & $executable --version

        if ($LASTEXITCODE -ne 0) {
            Write-Failure "$name version verification failed."
            continue
        }

        Write-Status PASS (
            "$name`: " + ($version | Out-String).Trim()
        )
    }
}

# ============================================================================
# Rust Toolchain Management
# ============================================================================

function Test-ToolchainInstalled {
    $toolchains = & $script:RustupPath toolchain list

    if ($LASTEXITCODE -ne 0) {
        throw 'Unable to list installed Rust toolchains.'
    }

    foreach ($line in $toolchains) {
        $name = ($line -split '\s+')[0]

        if ($name -eq $script:Toolchain) {
            return $true
        }
    }

    return $false
}

function Install-Toolchain {
    if (Test-ToolchainInstalled) {
        Write-Status SKIP (
            "$script:Toolchain is already installed."
        )

        return
    }

    Write-Status INFO "Installing $script:Toolchain..."

    Invoke-Rustup -Arguments @(
        'toolchain'
        'install'
        $script:Toolchain
        '--profile'
        'default'
    )

    if (-not (Test-ToolchainInstalled)) {
        throw (
            "Toolchain installation could not be verified: " +
            $script:Toolchain
        )
    }

    Write-Status PASS "$script:Toolchain installed."
}

function Update-Toolchain {
    Write-Status INFO "Updating $script:Toolchain..."

    Invoke-Rustup -Arguments @(
        'update'
        $script:Toolchain
    )

    Write-Status PASS "$script:Toolchain updated."
}

# ============================================================================
# Rust Component Management
# ============================================================================

function Get-InstalledComponents {
    $components = & $script:RustupPath component list `
        --toolchain $script:Toolchain `
        --installed

    if ($LASTEXITCODE -ne 0) {
        throw (
            "Unable to list installed components for " +
            "$script:Toolchain."
        )
    }

    return @(
        $components |
            ForEach-Object { $_.Trim() } |
            Where-Object {
                -not [string]::IsNullOrWhiteSpace($_)
            }
    )
}

function Test-ComponentInstalled {
    param(
        [string[]]$Installed,
        [string]$Component
    )

    $expectedNames = @(
        $Component
        "$Component-$script:Target"
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

    foreach ($component in $script:RequiredComponents) {
        if (
            Test-ComponentInstalled `
                -Installed $installed `
                -Component $component
        ) {
            Write-Status SKIP (
                "$component is already installed."
            )

            continue
        }

        Write-Status INFO (
            "Installing Rust component: $component"
        )

        Invoke-Rustup -Arguments @(
            'component'
            'add'
            $component
            '--toolchain'
            $script:Toolchain
        )

        Write-Status PASS "$component installed."

        $installed = Get-InstalledComponents
    }
}

function Test-Components {
    if (-not (Test-ToolchainInstalled)) {
        Write-Failure "$script:Toolchain is not installed."
        return
    }

    $installed = Get-InstalledComponents

    foreach ($component in $script:RequiredComponents) {
        if (
            Test-ComponentInstalled `
                -Installed $installed `
                -Component $component
        ) {
            Write-Status PASS "$component is installed."
        }
        else {
            Write-Failure (
                "$component is missing from $script:Toolchain."
            )
        }
    }
}

# ============================================================================
# Rust Executable Verification
# ============================================================================

function Test-RustCommands {
    foreach ($name in $script:RequiredCommands) {
        $command = Test-Application -Name $name

        if (-not $command) {
            continue
        }

        $version = & $script:RustupPath `
            run $script:Toolchain $name --version

        if ($LASTEXITCODE -ne 0) {
            Write-Failure "$name failed its version check."
            continue
        }

        Write-Status PASS (
            "$name`: " + ($version | Out-String).Trim()
        )
    }

    $active = & $script:RustupPath show active-toolchain

    if ($LASTEXITCODE -ne 0) {
        Write-Failure (
            'Unable to determine the active Rust toolchain.'
        )

        return
    }

    $activeName = ($active -split '\s+')[0]

    if ($activeName -eq $script:Toolchain) {
        Write-Status PASS "Active toolchain: $active"
    }
    else {
        Write-Status WARN (
            "Active toolchain is '$activeName', not " +
            "'$script:Toolchain'. The default will not be changed."
        )
    }
}

# ============================================================================
# Visual Studio Detection
# ============================================================================

function Find-VsWhere {
    $candidates = [System.Collections.Generic.List[string]]::new()

    # Standard Visual Studio Installer locations.
    if (-not [string]::IsNullOrWhiteSpace($script:ProgramFilesX86)) {
        $candidates.Add(
            (Join-Path $script:ProgramFilesX86 'Microsoft Visual Studio\Installer\vswhere.exe')
        )
    }

    if (-not [string]::IsNullOrWhiteSpace($env:ProgramFiles)) {
        $candidates.Add(
            (Join-Path $env:ProgramFiles 'Microsoft Visual Studio\Installer\vswhere.exe')
        )
    }

    # Some installations expose vswhere directly through PATH.
    $pathCommand = Get-Application -Name 'vswhere.exe'
    if ($pathCommand) {
        $candidates.Add($pathCommand.Source)
    }

    # Check Visual Studio Installer registry metadata when present.
    $registryPaths = @(
        'HKLM:\SOFTWARE\Microsoft\VisualStudio\Setup'
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\VisualStudio\Setup'
    )

    foreach ($registryPath in $registryPaths) {
        if (-not (Test-Path -LiteralPath $registryPath)) {
            continue
        }

        $properties = Get-ItemProperty -LiteralPath $registryPath `
            -ErrorAction SilentlyContinue

        if ($properties -and $properties.InstallerPath) {
            $candidates.Add(
                (Join-Path $properties.InstallerPath 'vswhere.exe')
            )
        }

        if ($properties -and $properties.SharedInstallationPath) {
            $candidates.Add(
                (Join-Path $properties.SharedInstallationPath 'vswhere.exe')
            )
        }
    }

    foreach ($candidate in $candidates) {
        if (
            -not [string]::IsNullOrWhiteSpace($candidate) -and
            (Test-Path -LiteralPath $candidate -PathType Leaf)
        ) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }

    return $null
}

function Get-VisualStudioRootFromCompiler {
    param(
        [Parameter(Mandatory)]
        [string]$CompilerPath
    )

    $fullPath = [System.IO.Path]::GetFullPath($CompilerPath)
    $pattern = '^(?<root>.+?)\\VC\\Tools\\MSVC\\[^\\]+\\bin\\Hostx64\\x64\\cl\.exe$'

    if ($fullPath -match $pattern) {
        return $Matches['root']
    }

    return $null
}

function Find-ExistingMSVCInstallation {
    $installationCandidates = [System.Collections.Generic.List[string]]::new()

    # First, use an already discoverable MSVC compiler. This supports
    # installations whose Visual Studio Installer metadata is unavailable.
    $pathCompiler = Get-Application -Name 'cl.exe'

    if ($pathCompiler -and $pathCompiler.Source) {
        $rootFromPath = Get-VisualStudioRootFromCompiler `
            -CompilerPath $pathCompiler.Source

        if ($rootFromPath) {
            $installationCandidates.Add($rootFromPath)
        }
    }

    # Also inspect standard Visual Studio install roots. This is a fallback
    # for an installed compiler that has not yet been added to this process PATH.
    $visualStudioParents = [System.Collections.Generic.List[string]]::new()

    if (-not [string]::IsNullOrWhiteSpace($script:ProgramFilesX86)) {
        $visualStudioParents.Add(
            (Join-Path $script:ProgramFilesX86 'Microsoft Visual Studio')
        )
    }

    if (-not [string]::IsNullOrWhiteSpace($env:ProgramFiles)) {
        $visualStudioParents.Add(
            (Join-Path $env:ProgramFiles 'Microsoft Visual Studio')
        )
    }

    foreach ($parent in $visualStudioParents) {
        if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
            continue
        }

        foreach ($yearDirectory in (Get-ChildItem -LiteralPath $parent -Directory -ErrorAction SilentlyContinue)) {
            foreach ($editionDirectory in (Get-ChildItem -LiteralPath $yearDirectory.FullName -Directory -ErrorAction SilentlyContinue)) {
                $installationCandidates.Add($editionDirectory.FullName)
            }
        }
    }

    # VSINSTALLDIR is useful when this script is launched from an existing
    # Visual Studio Developer PowerShell or Developer Command Prompt.
    if (-not [string]::IsNullOrWhiteSpace($env:VSINSTALLDIR)) {
        $installationCandidates.Insert(0, $env:VSINSTALLDIR.TrimEnd('\'))
    }

    $seen = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::OrdinalIgnoreCase
    )

    foreach ($installation in $installationCandidates) {
        if (-not $seen.Add($installation)) {
            continue
        }

        $vsDevCmd = Join-Path $installation 'Common7\Tools\VsDevCmd.bat'
        $toolsRoot = Join-Path $installation 'VC\Tools\MSVC'

        if (
            -not (Test-Path -LiteralPath $vsDevCmd -PathType Leaf) -or
            -not (Test-Path -LiteralPath $toolsRoot -PathType Container)
        ) {
            continue
        }

        $toolsets = Get-ChildItem -LiteralPath $toolsRoot -Directory -ErrorAction SilentlyContinue |
            Sort-Object Name -Descending

        foreach ($toolset in $toolsets) {
            $msvcBin = Join-Path $toolset.FullName 'bin\Hostx64\x64'
            $compiler = Join-Path $msvcBin 'cl.exe'
            $linker = Join-Path $msvcBin 'link.exe'

            if (
                (Test-Path -LiteralPath $compiler -PathType Leaf) -and
                (Test-Path -LiteralPath $linker -PathType Leaf)
            ) {
                return [pscustomobject]@{
                    Installation = $installation
                    VsDevCmd     = $vsDevCmd
                    Compiler     = $compiler
                    Linker       = $linker
                    Toolset      = $toolset.Name
                }
            }
        }
    }

    return $null
}

function Install-MSVCToolchain {
    Write-Host ''
    Write-Status INFO 'MSVC x64 was not found. Installing Visual Studio Build Tools...'

    $winget = Get-Application -Name 'winget'

    if (-not $winget) {
        throw @"
MSVC x64 is not installed and WinGet was not found.

Install Visual Studio Build Tools manually from:
https://visualstudio.microsoft.com/visual-cpp-build-tools/

Select the 'Desktop development with C++' workload, including the MSVC
x64/x86 build tools and a Windows 10/11 SDK. Then run .\rust.ps1 again.
"@
    }

    Write-Status INFO 'Requesting the Visual Studio C++ Build Tools workload.'
    Write-Status INFO 'This installs MSVC cl.exe, link.exe, VsDevCmd.bat, and the recommended Windows SDK.'

    # WinGet waits for the Visual Studio bootstrapper to finish. The installer
    # may request elevation; approve the Windows UAC prompt if one appears.
    & $winget.Source install `
        --id Microsoft.VisualStudio.BuildTools `
        -e `
        --source winget `
        --accept-package-agreements `
        --accept-source-agreements `
        --override '--wait --passive --norestart --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended'

    $installExitCode = $LASTEXITCODE

    if ($installExitCode -ne 0) {
        throw @"
WinGet could not complete the Visual Studio Build Tools installation.
Exit code: $installExitCode

Run PowerShell as Administrator and retry, or install manually from:
https://visualstudio.microsoft.com/visual-cpp-build-tools/

Choose 'Desktop development with C++' and include the MSVC x64/x86 tools
and Windows SDK.
"@
    }

    Write-Status PASS 'Visual Studio Build Tools installer completed.'
    Write-Status INFO 'Re-scanning Windows for the installed MSVC x64 toolchain...'
}

function Get-VisualStudioInstallation {
    param([switch]$InstallIfMissing)

    $script:VsWhere = Find-VsWhere
    $installation = $null

    # Prefer Visual Studio Installer's authoritative installation discovery.
    if ($script:VsWhere) {
        Write-Status PASS "vswhere found: $script:VsWhere"

        $vswhereResult = & $script:VsWhere `
            -latest `
            -products '*' `
            -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
            -property installationPath

        if ($LASTEXITCODE -eq 0 -and $vswhereResult) {
            $installation = ($vswhereResult | Select-Object -First 1).Trim()
        }
        else {
            Write-Status WARN 'vswhere did not report an MSVC x64 installation; checking existing compiler locations.'
        }
    }
    else {
        Write-Status WARN 'vswhere.exe was not found; checking existing MSVC compiler locations directly.'
    }

    if ($installation) {
        $vsDevCmd = Join-Path $installation 'Common7\Tools\VsDevCmd.bat'

        if (Test-Path -LiteralPath $vsDevCmd -PathType Leaf) {
            $script:VsInstallation = $installation
            $script:VsDevCmd = $vsDevCmd
        }
        else {
            Write-Status WARN "VsDevCmd.bat is missing from the vswhere installation: $vsDevCmd"
            $installation = $null
        }
    }

    # Fallback: detect a pre-existing x64 MSVC compiler/linker pair, then
    # recover the owning Visual Studio installation and activate its env.
    if (-not $installation) {
        $existing = Find-ExistingMSVCInstallation

        if ($existing) {
            $script:VsInstallation = $existing.Installation
            $script:VsDevCmd = $existing.VsDevCmd

            Write-Status PASS "Existing MSVC installation detected: $($existing.Installation)"
            Write-Status PASS "Existing MSVC toolset: $($existing.Toolset)"
            Write-Status PASS "Existing x64 compiler: $($existing.Compiler)"
            Write-Status PASS "Existing x64 linker: $($existing.Linker)"
            Write-Status PASS "Developer environment script found: $($existing.VsDevCmd)"
            return
        }
    }

    if (-not $script:VsInstallation -or -not $script:VsDevCmd) {
        if ($InstallIfMissing) {
            Install-MSVCToolchain

            # Re-run authoritative and fallback detection after installation.
            Get-VisualStudioInstallation
            return
        }

        throw @"
No Visual Studio MSVC x64 installation could be detected after scanning.

If you ran .\rust.ps1 -Check, check mode intentionally does not install
software. Run .\rust.ps1 without -Check to install Visual Studio Build Tools
through WinGet.

If automatic installation was already attempted, it may have been cancelled,
failed, or require a restart. Run the script again after the installer finishes.
You can also install manually from:
https://visualstudio.microsoft.com/visual-cpp-build-tools/

The required components are the Desktop development with C++ workload,
MSVC x64/x86 tools, and a Windows 10/11 SDK.
"@
    }

    Write-Status PASS "Visual Studio detected: $script:VsInstallation"
    Write-Status PASS "Developer environment script found: $script:VsDevCmd"
}

# ============================================================================
# Activate MSVC x64 Developer Environment
# ============================================================================

function Initialize-MSVCEnvironment {
    param([switch]$InstallIfMissing)
    Write-Host ''

    Write-Status INFO 'Initializing MSVC x64 developer environment...'

    Get-VisualStudioInstallation -InstallIfMissing:$InstallIfMissing

    # VsDevCmd must be executed through cmd.exe because it is a batch file.
    # Export its environment using SET, then import it into this PowerShell
    # process. No persistent Windows environment variables are modified.

    $command = 'call "{0}" -no_logo -arch=x64 -host_arch=x64 >nul && set' -f `
        $script:VsDevCmd

    $environmentOutput = & $env:ComSpec /d /s /c $command 2>&1
    $exitCode = $LASTEXITCODE

    if ($exitCode -ne 0) {
        throw (
            "VsDevCmd.bat failed to initialize MSVC. Exit code: $exitCode"
        )
    }

    foreach ($line in $environmentOutput) {
        $entry = [string]$line

        # Ignore cmd.exe pseudo environment variables such as =C:=
        if ($entry -match '^([^=]+)=(.*)$') {
            $name = $Matches[1]
            $value = $Matches[2]

            [Environment]::SetEnvironmentVariable(
                $name,
                $value,
                [EnvironmentVariableTarget]::Process
            )
        }
    }

    if ($env:VSCMD_ARG_TGT_ARCH -ne 'x64') {
        throw (
            'Visual Studio did not initialize the x64 target architecture.'
        )
    }

    if ($env:VSCMD_ARG_HOST_ARCH -ne 'x64') {
        throw (
            'Visual Studio did not initialize the x64 host architecture.'
        )
    }

    if ([string]::IsNullOrWhiteSpace($env:VCToolsInstallDir)) {
        throw 'VCToolsInstallDir was not initialized by VsDevCmd.'
    }

    $script:MSVCVersion = $env:VCToolsVersion

    $msvcBin = Join-Path $env:VCToolsInstallDir `
        'bin\Hostx64\x64'

    $compiler = Join-Path $msvcBin 'cl.exe'
    $linker = Join-Path $msvcBin 'link.exe'

    if (-not (Test-Path -LiteralPath $compiler -PathType Leaf)) {
        throw "MSVC x64 compiler is missing: $compiler"
    }

    if (-not (Test-Path -LiteralPath $linker -PathType Leaf)) {
        throw "MSVC x64 linker is missing: $linker"
    }

    $script:MSVCCompiler = $compiler
    $script:MSVCLinker = $linker

    # Make MSVC tools the first available compiler/linker on PATH.
    $env:Path = "$msvcBin;$env:Path"

    Write-Status PASS 'MSVC x64 environment activated.'
    Write-Status PASS "MSVC toolset version: $script:MSVCVersion"
    Write-Status PASS "MSVC x64 compiler: $script:MSVCCompiler"
    Write-Status PASS "MSVC x64 linker: $script:MSVCLinker"
}

# ============================================================================
# Configure Rust and Native Build Tools
# ============================================================================

function Set-RustMSVCEnvironment {
    if (
        -not $script:MSVCCompiler -or
        -not $script:MSVCLinker
    ) {
        throw 'MSVC environment must be initialized before configuring Rust.'
    }

    # Native build tools using the MSVC compiler.
    $env:CC = 'cl.exe'
    $env:CXX = 'cl.exe'

    $env:CC_x86_64_pc_windows_msvc = 'cl.exe'
    $env:CXX_x86_64_pc_windows_msvc = 'cl.exe'

    # Cargo must use the MSVC x64 linker for the Rust MSVC target.
    $env:CARGO_TARGET_X86_64_PC_WINDOWS_MSVC_LINKER = 'link.exe'

    # Ensure the target is available in the current Rust environment.
    $env:RUSTUP_TOOLCHAIN = $script:Toolchain

    Write-Status PASS 'Native CC configured to use MSVC cl.exe.'
    Write-Status PASS 'Native CXX configured to use MSVC cl.exe.'
    Write-Status PASS 'Cargo linker configured to use MSVC link.exe.'
    Write-Status PASS "Rust toolchain selected for this process: $script:Toolchain"
}

# ============================================================================
# Verify Actual MSVC Compiler and Linker
# ============================================================================

function Test-MSVCExecutables {
    Write-Host ''

    Write-Status INFO 'Verifying actual MSVC x64 compiler and linker...'

    $compilerCommand = Get-Application -Name 'cl.exe'
    $linkerCommand = Get-Application -Name 'link.exe'

    if (-not $compilerCommand) {
        Write-Failure 'MSVC cl.exe is not discoverable through PATH.'
    }
    elseif (
        $compilerCommand.Source -ine $script:MSVCCompiler
    ) {
        Write-Failure (
            "Unexpected compiler selected: $($compilerCommand.Source)"
        )
    }
    else {
        Write-Status PASS (
            "Selected MSVC compiler: $($compilerCommand.Source)"
        )
    }

    if (-not $linkerCommand) {
        Write-Failure 'MSVC link.exe is not discoverable through PATH.'
    }
    elseif (
        $linkerCommand.Source -ine $script:MSVCLinker
    ) {
        Write-Failure (
            "Unexpected linker selected: $($linkerCommand.Source)"
        )
    }
    else {
        Write-Status PASS (
            "Selected MSVC linker: $($linkerCommand.Source)"
        )
    }

    Write-Status INFO 'Checking compiler version...'

    $compilerOutput = & $script:MSVCCompiler /Bv 2>&1

    if ($LASTEXITCODE -ne 0) {
        Write-Failure 'MSVC compiler version check failed.'
    }
    else {
        $compilerOutput |
            Select-Object -First 5 |
            ForEach-Object {
                Write-Host $_
            }

        Write-Status PASS 'MSVC compiler is executable.'
    }

    Write-Status INFO 'Checking MSVC linker...'

    $linkerOutput = & $script:MSVCLinker /? 2>&1

    if ($LASTEXITCODE -ne 0) {
        Write-Failure 'MSVC linker verification failed.'
    }
    else {
        $linkerOutput |
            Select-Object -First 3 |
            ForEach-Object {
                Write-Host $_
            }

        Write-Status PASS 'MSVC linker is executable.'
    }

    if ($env:VSCMD_ARG_TGT_ARCH -ne 'x64') {
        Write-Failure 'MSVC target architecture is not x64.'
    }
    else {
        Write-Status PASS 'MSVC target architecture: x64.'
    }

    if ($env:VSCMD_ARG_HOST_ARCH -ne 'x64') {
        Write-Failure 'MSVC host architecture is not x64.'
    }
    else {
        Write-Status PASS 'MSVC host architecture: x64.'
    }
}

# ============================================================================
# Windows SDK Detection and Verification
# ============================================================================

function Get-WindowsSdkRoot {
    $registryPaths = @(
        'HKLM:\SOFTWARE\Microsoft\Windows Kits\Installed Roots'
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows Kits\Installed Roots'
    )

    foreach ($registryPath in $registryPaths) {
        if (-not (Test-Path $registryPath)) {
            continue
        }

        $properties = Get-ItemProperty `
            -Path $registryPath `
            -ErrorAction SilentlyContinue

        if (
            $properties -and
            -not [string]::IsNullOrWhiteSpace($properties.KitsRoot10)
        ) {
            return $properties.KitsRoot10.TrimEnd('\')
        }
    }

    $fallback = Join-Path $script:ProgramFilesX86 'Windows Kits\10'

    if (Test-Path $fallback -PathType Container) {
        return $fallback
    }

    return $null
}

function Test-WindowsSdk {
    Write-Host ''

    Write-Status INFO 'Checking Windows SDK x64 libraries...'

    $script:WindowsSdkRoot = Get-WindowsSdkRoot

    if (-not $script:WindowsSdkRoot) {
        Write-Failure 'Windows SDK installation root was not found.'
        return
    }

    $includeRoot = Join-Path $script:WindowsSdkRoot 'Include'
    $libRoot = Join-Path $script:WindowsSdkRoot 'Lib'

    if (-not (Test-Path $includeRoot -PathType Container)) {
        Write-Failure "Windows SDK Include directory is missing: $includeRoot"
        return
    }

    if (-not (Test-Path $libRoot -PathType Container)) {
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
            Where-Object {
                $libVersions -contains $_
            } |
            Sort-Object -Descending
    )

    if ($matchingVersions.Count -eq 0) {
        Write-Failure (
            'No matching Windows SDK Include and Lib versions were found.'
        )
        return
    }

    $validSdk = $null

    foreach ($version in $matchingVersions) {
        $sdkInclude = Join-Path $includeRoot $version
        $sdkLib = Join-Path $libRoot "$version\um\x64"

        $umHeader = Join-Path $sdkInclude 'um\Windows.h'
        $sharedHeader = Join-Path $sdkInclude 'shared\Windows.h'
        $kernelLib = Join-Path $sdkLib 'kernel32.lib'

        if (
            (Test-Path $umHeader -PathType Leaf) -and
            (Test-Path $sharedHeader -PathType Leaf) -and
            (Test-Path $kernelLib -PathType Leaf)
        ) {
            $validSdk = $version
            break
        }
    }

    if (-not $validSdk) {
        Write-Failure (
            'Windows SDK x64 headers or kernel32.lib are missing.'
        )
        return
    }

    $script:WindowsSdkVersion = $validSdk

    Write-Status PASS "Windows SDK root: $script:WindowsSdkRoot"
    Write-Status PASS "Windows SDK version: $validSdk"
    Write-Status PASS 'Windows SDK headers found.'
    Write-Status PASS 'Windows SDK x64 libraries found.'
}

# ============================================================================
# Rust Target Verification
# ============================================================================

function Test-RustTarget {
    Write-Host ''

    Write-Status INFO "Checking Rust target: $script:Target..."

    $targets = & $script:RustupPath target list `
        --toolchain $script:Toolchain `
        --installed

    if ($LASTEXITCODE -ne 0) {
        Write-Failure 'Unable to list installed Rust targets.'
        return
    }

    if ($targets -contains $script:Target) {
        Write-Status PASS "Rust target installed: $script:Target"
    }
    else {
        if ($Check) {
            Write-Failure "Rust target is missing: $script:Target"
            return
        }

        Write-Status INFO "Installing Rust target: $script:Target"

        Invoke-Rustup -Arguments @(
            'target'
            'add'
            $script:Target
            '--toolchain'
            $script:Toolchain
        )

        Write-Status PASS "Rust target installed: $script:Target"
    }
}

# ============================================================================
# Main Execution
# ============================================================================

try {
    if ($Check -and $Update) {
        throw 'Use either -Check or -Update, not both.'
    }

    Write-Host ''

    Write-Status INFO (
        'Preparing Rust dependencies for nvim-config...'
    )

    Test-PowerShellVersion
    Test-Windows

    Update-ProcessPath

    # Rustup installation and detection.
    if ($Check) {
        Test-Rustup
    }
    else {
        Test-Rustup -InstallIfMissing
    }

    Test-RustVersions

    # Initialize the actual Visual Studio x64 build environment.
    Initialize-MSVCEnvironment -InstallIfMissing:(-not $Check)

    # Configure Rust and native builds to use MSVC.
    Set-RustMSVCEnvironment

    # Verify the compiler and linker selected by PATH.
    Test-MSVCExecutables

    # Verify Windows SDK headers and libraries.
    Test-WindowsSdk

    if ($Check) {
        Write-Status INFO 'Check mode: Rust installation is disabled.'

        if (Test-ToolchainInstalled) {
            Write-Status PASS "$script:Toolchain is installed."
        }
        else {
            Write-Failure "$script:Toolchain is not installed."
        }
    }
    else {
        Install-Toolchain

        if ($Update) {
            Update-Toolchain
        }

        Update-ProcessPath

        # Re-activate MSVC after PATH refresh.
        Initialize-MSVCEnvironment
        Set-RustMSVCEnvironment

        Install-Components
    }

    # Verify components, targets, and Rust executables.
    Test-Components
    Test-RustTarget
    Test-RustCommands

    Write-Host ''

    if ($script:Failed) {
        Write-Status FAIL (
            'Rust dependency verification completed with failures.'
        )

        exit 1
    }

    Write-Host ''
    Write-Status PASS 'MSVC x64 compiler selected.'
    Write-Status PASS 'MSVC x64 linker selected.'
    Write-Status PASS 'Cargo configured to use MSVC link.exe.'
    Write-Status PASS 'Rust target: x86_64-pc-windows-msvc.'

    Write-Status PASS (
        'Rust dependency installation and verification completed.'
    )

    Write-Host ''
    Write-Status INFO (
        'MSVC environment changes apply only to this PowerShell process.'
    )
    Write-Status INFO (
        'Run this script again in a new terminal before building Rust projects.'
    )

    exit 0
}
catch {
    Write-Host ''

    Write-Status FAIL $_.Exception.Message

    exit 1
}
