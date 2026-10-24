# Provision core Windows dependencies, Neovim providers, navigation and
# search tools, and development tools.
#
# Usage:
#   .\scripts\win-depend.ps1
#
# Core dependencies:
#   - Neovim >= 0.12.0
#   - Git
#   - cURL installed through WinGet
#
# Neovim providers:
#   - Node.js + the global `neovim` npm package
#   - Python 3.14 + the `pynvim` Python package
#
# Navigation and search tools:
#   - ripgrep (rg; fast content search for native search workflows)
#   - fd (fast file and directory discovery)
#   - fzf (required by the fzf-lua Neovim plugin)
#
# Development tools:
#   - ShellCheck
#   - WinLibs GCC/G++ POSIX UCRT toolchain
#   - tree-sitter-cli >= 0.26.1
#   - GNU tar bundled with Git for Windows
#
# Requirements:
#   - Windows
#   - WinGet (Microsoft.DesktopAppInstaller)
#
# Behavior:
#   - Reuses existing installations when they satisfy requirements.
#   - Installs missing dependencies through WinGet.
#   - Installs missing Neovim provider packages through npm or pip.
#   - Verifies dependencies and provider packages after installation.
#   - Continues with independent steps when one step fails.
#   - Returns exit code 1 if any required step fails.
#   - Does not rewrite Neovim configuration files.
#   - Does not remove existing Neovim configuration or data.
#   - Refreshes PATH only for this PowerShell process and its children.
#   - Sets CC to the verified WinLibs GCC executable for this process.
#   - Uses Git for Windows' bundled tar.exe instead of a separate tar package.
#
# Optional providers:
#   Perl and Ruby are not installed by this script. They are disabled
#   separately in the Neovim configuration because they are not required
#   by the current project.
#
# Notes:
#   This script provisions Tree-sitter prerequisites. It does not install
#   Neovim parsers or guarantee that every parser compiles successfully.
#   Environment changes apply to this PowerShell process and its children.
#   A new terminal session must run this script again before launching
#   Neovim if it needs the configured compiler environment.

[CmdletBinding()]
param()

# Enable stricter variable and expression checks.
# Stop on PowerShell errors so the current step can report failures cleanly.
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Track failures, installations, and failure messages for the final summary.
$script:Failed = $false
$script:InstalledAnyPackage = $false
$script:Failures = [System.Collections.Generic.List[string]]::new()

# Minimum supported versions.
$minimumNeovimVersion = [version]::new(0, 12, 0)
$minimumTreeSitterVersion = [version]::new(0, 26, 1)

# Official WinGet package identifiers used when an application is missing.
$packages = @{
    Neovim     = "Neovim.Neovim"
    Git        = "Git.Git"
    Curl       = "cURL.cURL"
    Node       = "OpenJS.NodeJS"
    Python     = "Python.Python.3.14"
    ShellCheck = "koalaman.shellcheck"
    Ripgrep    = "BurntSushi.ripgrep.MSVC"
    Fd         = "sharkdp.fd"
    Fzf        = "junegunn.fzf"
    WinLibs    = "BrechtSanders.WinLibs.POSIX.UCRT"
    TreeSitter = "tree-sitter.tree-sitter-cli"
}

# Print a consistently formatted status message using a color associated
# with the status category.
function Write-Status {
    param(
        [Parameter(Mandatory)]
        [ValidateSet("INFO", "PASS", "INSTALL", "WARN", "FAIL")]
        [string]$Status,

        [Parameter(Mandatory)]
        [string]$Message
    )

    $color = switch ($Status) {
        "INFO"    { "Cyan" }
        "PASS"    { "Green" }
        "INSTALL" { "Yellow" }
        "WARN"    { "Yellow" }
        "FAIL"    { "Red" }
    }

    Write-Host ("[{0}] {1}" -f $Status, $Message) -ForegroundColor $color
}

# Run an independent setup step.
#
# A failure is recorded instead of terminating the entire script, allowing
# later independent dependencies and providers to be checked.
function Invoke-Step {
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [scriptblock]$Action
    )

    Write-Host ""
    Write-Host $Name -ForegroundColor Cyan

    try {
        & $Action
    }
    catch {
        $message = $_.Exception.Message
        $script:Failed = $true
        $script:Failures.Add("$Name $message")
        Write-Status -Status FAIL -Message $message
        Write-Status -Status WARN -Message "Continuing with the remaining steps."
    }
}

# Find the first executable command available on PATH.
#
# Restrict the result to applications to avoid accidentally selecting
# aliases, functions, or cmdlets when an external executable is required.
function Get-Application {
    param(
        [Parameter(Mandatory)]
        [string[]]$Names
    )

    foreach ($name in $Names) {
        $command = Get-Command $name -ErrorAction SilentlyContinue |
            Where-Object { $_.CommandType -eq "Application" } |
            Select-Object -First 1

        if ($command) {
            return $command
        }
    }

    return $null
}

# Ensure Windows System32 is available on PATH.
#
# Append System32 only when missing so it remains a fallback instead of
# taking precedence over WinGet-managed tools.
function Ensure-System32OnPath {
    if ([string]::IsNullOrWhiteSpace($env:WINDIR)) {
        throw "The WINDIR environment variable is missing."
    }

    $system32 = Join-Path $env:WINDIR "System32"

    if (-not (Test-Path -LiteralPath $system32 -PathType Container)) {
        throw "Windows System32 directory was not found: $system32"
    }

    $pathEntries = @(
        $env:Path -split ";" |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    )

    # Compare paths without regard to case or a trailing backslash.
    foreach ($entry in $pathEntries) {
        if ([string]::Equals(
                $entry.Trim().TrimEnd("\"),
                $system32.TrimEnd("\"),
                [StringComparison]::OrdinalIgnoreCase
            )) {
            return
        }
    }

    if ([string]::IsNullOrWhiteSpace($env:Path)) {
        $env:Path = $system32
    }
    else {
        $env:Path = "$env:Path;$system32"
    }

    Write-Status -Status INFO -Message "Added System32 to this process's PATH as a fallback."
}

# Refresh this PowerShell process's PATH after a WinGet installation.
#
# Start with the current PATH to preserve process-specific entries, then
# append machine and user PATH entries that are not already present.
# This does not permanently modify the Windows PATH environment variables.
function Refresh-ProcessPath {
    $machinePath = [Environment]::GetEnvironmentVariable(
        "Path",
        [EnvironmentVariableTarget]::Machine
    )

    $userPath = [Environment]::GetEnvironmentVariable(
        "Path",
        [EnvironmentVariableTarget]::User
    )

    $currentEntries = @(
        $env:Path -split ";" |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    )

    $persistentEntries = @(
        @($machinePath, $userPath) |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
            ForEach-Object { $_ -split ";" } |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    )

    # Use a case-insensitive set to prevent duplicate PATH entries.
    $combinedEntries = [System.Collections.Generic.List[string]]::new()
    $seenEntries = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::OrdinalIgnoreCase
    )

    foreach ($entry in @($currentEntries) + @($persistentEntries)) {
        $trimmedEntry = $entry.Trim()
        $normalizedEntry = $trimmedEntry.TrimEnd("\")

        if ([string]::IsNullOrWhiteSpace($normalizedEntry)) {
            continue
        }

        if ($seenEntries.Add($normalizedEntry)) {
            $combinedEntries.Add($trimmedEntry)
        }
    }

    $env:Path = $combinedEntries -join ";"

    # Preserve System32 as a fallback after refreshing PATH.
    Ensure-System32OnPath
}

# Locate WinGet and fail with an actionable message if it is unavailable.
function Get-Winget {
    $winget = Get-Application -Names @("winget.exe", "winget")

    if (-not $winget) {
        throw "WinGet is unavailable. Install or repair Microsoft App Installer."
    }

    return $winget
}

# Install a missing package using its exact WinGet package identifier.
#
# This function handles missing packages, not upgrades to already-installed
# packages.
function Invoke-WingetInstall {
    param(
        [Parameter(Mandatory)]
        [string]$PackageId
    )

    $winget = Get-Winget

    Write-Status -Status INSTALL -Message "Installing $PackageId through WinGet..."

    $arguments = @(
        "install"
        "--id", $PackageId
        "--exact"
        "--accept-source-agreements"
        "--accept-package-agreements"
        "--silent"
    )

    & $winget.Source @arguments
    $exitCode = $LASTEXITCODE

    if ($exitCode -ne 0) {
        throw "WinGet failed to install '$PackageId' (exit code $exitCode)."
    }

    $script:InstalledAnyPackage = $true

    # Make newly installed commands discoverable in this process.
    Refresh-ProcessPath
}

# Ensure a command exists, install its package if necessary, and verify it
# using the supplied arguments.
function Ensure-Command {
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string[]]$Commands,

        [Parameter(Mandatory)]
        [string]$PackageId,

        [Parameter(Mandatory)]
        [string[]]$VerifyArguments
    )

    $command = Get-Application -Names $Commands

    if (-not $command) {
        Invoke-WingetInstall -PackageId $PackageId
        $command = Get-Application -Names $Commands
    }

    if (-not $command) {
        throw "$Name was not found after installation. Check PATH and rerun the script."
    }

    $output = & $command.Source @VerifyArguments 2>&1
    $exitCode = $LASTEXITCODE

    if ($exitCode -ne 0) {
        throw "$Name verification failed (exit code $exitCode)."
    }

    $firstLine = $output | Select-Object -First 1
    Write-Status -Status PASS -Message "$Name verified: $firstLine"
}

# Read the installed Neovim version from nvim --version.
#
# Return $null if Neovim is absent or its version cannot be parsed.
function Get-NeovimVersion {
    $nvim = Get-Application -Names @("nvim.exe", "nvim")

    if (-not $nvim) {
        return $null
    }

    $output = & $nvim.Source --version 2>&1
    $exitCode = $LASTEXITCODE

    if ($exitCode -ne 0) {
        return $null
    }

    $firstLine = $output | Select-Object -First 1

    if ("$firstLine" -match '^NVIM v(\d+)\.(\d+)\.(\d+)') {
        return [version]::new(
            [int]$Matches[1],
            [int]$Matches[2],
            [int]$Matches[3]
        )
    }

    return $null
}

# Ensure Neovim meets the project's minimum version requirement.
#
# Install Neovim if absent. If an older version is present, attempt a
# WinGet upgrade and verify the resulting version.
function Ensure-Neovim {
    $version = Get-NeovimVersion

    if ($null -eq $version) {
        $existing = Get-Application -Names @("nvim.exe", "nvim")

        if ($existing) {
            throw "Neovim is present, but its version could not be determined."
        }

        Invoke-WingetInstall -PackageId $packages.Neovim
        $version = Get-NeovimVersion
    }

    if ($null -eq $version) {
        throw "Could not determine the installed Neovim version."
    }

    if ($version -lt $minimumNeovimVersion) {
        Write-Status -Status WARN -Message (
            "Neovim $version is below the required version $minimumNeovimVersion."
        )

        $winget = Get-Winget
        Write-Status -Status INSTALL -Message "Attempting to upgrade Neovim..."

        $arguments = @(
            "upgrade"
            "--id", $packages.Neovim
            "--exact"
            "--accept-source-agreements"
            "--accept-package-agreements"
            "--silent"
        )

        & $winget.Source @arguments
        $exitCode = $LASTEXITCODE

        if ($exitCode -ne 0) {
            throw "WinGet could not upgrade Neovim (exit code $exitCode)."
        }

        $script:InstalledAnyPackage = $true
        Refresh-ProcessPath
        $version = Get-NeovimVersion
    }

    if ($null -eq $version -or $version -lt $minimumNeovimVersion) {
        throw "Neovim must be version $minimumNeovimVersion or later."
    }

    Write-Status -Status PASS -Message "Neovim $version meets the minimum requirement."
}

# Ensure the cURL executable provided by WinGet exists and works.
#
# Check the WinGet Links path directly so a different curl.exe elsewhere
# on PATH cannot hide a missing WinGet-managed cURL installation.
function Ensure-Curl {
    if ([string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) {
        throw "LOCALAPPDATA is missing; cannot locate WinGet's Links directory."
    }

    $curlPath = Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Links\curl.exe"

    if (-not (Test-Path -LiteralPath $curlPath -PathType Leaf)) {
        Invoke-WingetInstall -PackageId $packages.Curl
    }

    if (-not (Test-Path -LiteralPath $curlPath -PathType Leaf)) {
        throw "The WinGet cURL executable link was not found: $curlPath"
    }

    $output = & $curlPath --version 2>&1
    $exitCode = $LASTEXITCODE

    if ($exitCode -ne 0) {
        throw "WinGet-managed cURL verification failed (exit code $exitCode)."
    }

    $firstLine = $output | Select-Object -First 1

    if ("$firstLine" -notmatch '^curl\s+') {
        throw "Unexpected cURL version response: $firstLine"
    }

    Write-Status -Status PASS -Message "cURL verified: $firstLine"
    Write-Status -Status INFO -Message "cURL executable: $curlPath"
}

# Ensure Git for Windows' bundled GNU tar is available.
#
# Put Git's usr\bin directory first on this process's PATH so Tree-sitter
# resolves the verified GNU tar rather than an unrelated tar executable.
function Ensure-GitTar {
    $git = Get-Application -Names @("git.exe", "git")

    if (-not $git) {
        throw "Git is required before configuring the bundled tar executable."
    }

    $gitRoot = Split-Path (Split-Path $git.Source -Parent) -Parent
    $gitUsrBin = Join-Path $gitRoot "usr\bin"
    $gitTar = Join-Path $gitUsrBin "tar.exe"

    if (-not (Test-Path -LiteralPath $gitTar -PathType Leaf)) {
        throw "Git's bundled tar.exe was not found: $gitTar"
    }

    $remainingEntries = @(
        $env:Path -split ";" |
            Where-Object {
                -not [string]::IsNullOrWhiteSpace($_) -and
                -not [string]::Equals(
                    $_.Trim().TrimEnd("\"),
                    $gitUsrBin.TrimEnd("\"),
                    [StringComparison]::OrdinalIgnoreCase
                )
            }
    )

    $env:Path = (@($gitUsrBin) + $remainingEntries) -join ";"

    $output = & $gitTar --version 2>&1
    $exitCode = $LASTEXITCODE

    if ($exitCode -ne 0) {
        throw "Git's bundled tar.exe verification failed (exit code $exitCode)."
    }

    $firstLine = $output | Select-Object -First 1

    if ("$firstLine" -notmatch '^tar \(GNU tar\)') {
        throw "Git's bundled tar.exe returned an unexpected version response: $firstLine"
    }

    $tarCommand = Get-Application -Names @("tar.exe", "tar")

    if (
        -not $tarCommand -or
        -not [string]::Equals(
            $tarCommand.Source,
            $gitTar,
            [StringComparison]::OrdinalIgnoreCase
        )
    ) {
        throw "tar was not resolved to Git's bundled executable after PATH update."
    }

    Write-Status -Status PASS -Message "GNU tar verified: $firstLine"
    Write-Status -Status INFO -Message "Tar executable: $gitTar"
}

# Ensure Node.js and Neovim's Node.js provider package are available.
#
# Reuse an existing Node.js runtime instead of asking WinGet to install an
# already-installed package. Install the global npm package only if missing.
function Ensure-NodeProvider {
    $node = Get-Application -Names @("node.exe", "node")

    if (-not $node) {
        Invoke-WingetInstall -PackageId $packages.Node
        $node = Get-Application -Names @("node.exe", "node")
    }

    if (-not $node) {
        throw "Node.js was not found after installation."
    }

    $nodeVersion = & $node.Source --version 2>&1
    $nodeExitCode = $LASTEXITCODE

    if ($nodeExitCode -ne 0 -or "$nodeVersion" -notmatch '^v\d+\.\d+\.\d+') {
        throw "Node.js was found, but its version check failed."
    }

    Write-Status -Status PASS -Message "Node.js runtime: $nodeVersion"

    # npm is installed with the standard Node.js Windows distribution.
    $npm = Get-Application -Names @("npm.cmd", "npm")

    if (-not $npm) {
        throw "npm was not found. Repair the existing Node.js installation."
    }

    # Check whether the Neovim provider package is already globally installed.
    $npmList = & $npm.Source list --global neovim --depth=0 2>&1
    $npmListExitCode = $LASTEXITCODE

    if ($npmListExitCode -eq 0 -and ($npmList -join "`n") -match 'neovim@') {
        Write-Status -Status PASS -Message "Neovim npm provider package is already installed."
        return
    }

    # Install the provider package required by Neovim's Node.js provider.
    Write-Status -Status INSTALL -Message "Installing the Neovim Node.js provider package..."

    & $npm.Source install --global neovim
    $npmExitCode = $LASTEXITCODE

    if ($npmExitCode -ne 0) {
        throw "npm failed to install 'neovim' (exit code $npmExitCode). Check the Windows clock, TLS certificate validity, and npm registry connectivity."
    }

    Refresh-ProcessPath

    # Verify that npm reports the package as globally installed.
    $npmList = & $npm.Source list --global neovim --depth=0 2>&1
    $npmListExitCode = $LASTEXITCODE

    if ($npmListExitCode -ne 0 -or ($npmList -join "`n") -notmatch 'neovim@') {
        throw "The global npm neovim package could not be verified."
    }

    Write-Status -Status PASS -Message "Neovim Node.js provider package installed and verified."
}

# Locate a usable Python 3 interpreter.
#
# Prefer the Windows Python launcher so the script can select Python 3.14
# explicitly and avoid mistaking a Microsoft Store execution alias for
# an installed interpreter. Fall back to another Python 3 interpreter.
#
# The returned object contains the executable, arguments required to select
# the interpreter, and the detected version.
function Get-PythonCommand {
    $launcher = Get-Application -Names @("py.exe", "py")

    if ($launcher) {
        # Prefer the project's selected Python 3.14 runtime.
        $probe = & $launcher.Source -3.14 --version 2>&1

        if ($LASTEXITCODE -eq 0 -and "$probe" -match '^Python 3\.14\.') {
            return @{
                Executable = $launcher.Source
                PrefixArgs = @("-3.14")
                Version    = "$probe"
            }
        }

        # If Python 3.14 is unavailable, accept another Python 3 version.
        $probe = & $launcher.Source -3 --version 2>&1

        if ($LASTEXITCODE -eq 0 -and "$probe" -match '^Python 3\.') {
            return @{
                Executable = $launcher.Source
                PrefixArgs = @("-3")
                Version    = "$probe"
            }
        }
    }

    # Fall back to python.exe if it resolves to a working Python 3 runtime.
    $python = Get-Application -Names @("python.exe", "python")

    if ($python) {
        $probe = & $python.Source --version 2>&1

        if ($LASTEXITCODE -eq 0 -and "$probe" -match '^Python 3\.') {
            return @{
                Executable = $python.Source
                PrefixArgs = @()
                Version    = "$probe"
            }
        }
    }

    return $null
}

# Ensure the selected Python interpreter has pip and the pynvim package.
#
# The package is installed into the interpreter selected by Get-PythonCommand,
# not into an unrelated Python installation. Existing working installations
# are reused.
function Ensure-PythonProvider {
    $python = Get-PythonCommand

    if (-not $python) {
        Invoke-WingetInstall -PackageId $packages.Python
        $python = Get-PythonCommand
    }

    if (-not $python) {
        throw "Python 3 was not found after installing $($packages.Python). Open a new PowerShell session and rerun the script."
    }

    Write-Status -Status PASS -Message "Python runtime: $($python.Version)"

    # Verify pip is available for the selected interpreter.
    $pipArgs = @($python.PrefixArgs) + @("-m", "pip", "--version")
    & $python.Executable @pipArgs 2>$null
    $pipExitCode = $LASTEXITCODE

    if ($pipExitCode -ne 0) {
        # Bootstrap pip only when the selected interpreter does not provide it.
        Write-Status -Status INSTALL -Message "Bootstrapping pip for Python 3..."

        $ensurePipArgs = @($python.PrefixArgs) + @("-m", "ensurepip", "--upgrade")
        & $python.Executable @ensurePipArgs
        $ensurePipExitCode = $LASTEXITCODE

        if ($ensurePipExitCode -ne 0) {
            throw "Could not bootstrap pip for the selected Python interpreter."
        }
    }

    # Test whether pynvim can be imported by the selected interpreter.
    $showArgs = @($python.PrefixArgs) + @("-c", "import pynvim; print(pynvim.__version__)")
    & $python.Executable @showArgs 2>$null
    $providerExists = ($LASTEXITCODE -eq 0)

    if (-not $providerExists) {
        # Install pynvim only if it is missing or cannot be imported.
        Write-Status -Status INSTALL -Message "Installing/updating pynvim..."

        $installArgs = @($python.PrefixArgs) + @("-m", "pip", "install", "--upgrade", "pynvim")
        & $python.Executable @installArgs
        $installExitCode = $LASTEXITCODE

        if ($installExitCode -ne 0) {
            throw "pip failed to install pynvim (exit code $installExitCode)."
        }
    }
    else {
        Write-Status -Status PASS -Message "pynvim is already importable."
    }

    # Verify the final package import and report its installed version.
    $verifyArgs = @($python.PrefixArgs) + @("-c", "import pynvim; print('pynvim', pynvim.__version__)")
    & $python.Executable @verifyArgs
    $verifyExitCode = $LASTEXITCODE

    if ($verifyExitCode -ne 0) {
        throw "pynvim could not be imported by the selected Python interpreter."
    }

    # Do not write provider paths into Neovim configuration or persist
    # environment variables. Neovim performs provider discovery separately.
    Write-Status -Status PASS -Message "Python provider package installed and verified."
    Write-Status -Status INFO -Message "Python launcher: $($python.Executable) $($python.PrefixArgs -join ' ')"
}

# Ensure ShellCheck is installed and returns a recognizable version report.
#
# ShellCheck is a development tool used to validate shell scripts. It is
# independent of the Node.js and Python provider setup.
function Ensure-ShellCheck {
    $shellCheck = Get-Application -Names @("shellcheck.exe", "shellcheck")

    if (-not $shellCheck) {
        Invoke-WingetInstall -PackageId $packages.ShellCheck
        $shellCheck = Get-Application -Names @("shellcheck.exe", "shellcheck")
    }

    if (-not $shellCheck) {
        throw "ShellCheck was not found after installing $($packages.ShellCheck)."
    }

    $output = & $shellCheck.Source --version 2>&1
    $exitCode = $LASTEXITCODE

    if ($exitCode -ne 0) {
        throw "ShellCheck verification failed (exit code $exitCode)."
    }

    # ShellCheck includes a line formatted as "version: x.y.z".
    $versionLine = $output |
        Where-Object { "$_" -match '^version:\s+' } |
        Select-Object -First 1

    if (-not $versionLine) {
        throw "ShellCheck returned an unexpected version response."
    }

    Write-Status -Status PASS -Message "ShellCheck verified: $versionLine"
}

# Ensure ripgrep is installed and available for native search workflows.
#
# Reuse an existing rg executable when available. Otherwise, install
# ripgrep through WinGet and verify its version output.
function Ensure-Ripgrep {
    Ensure-Command `
        -Name "ripgrep (rg)" `
        -Commands @("rg.exe", "rg") `
        -PackageId $packages.Ripgrep `
        -VerifyArguments @("--version")
}

# Ensure fd is installed and available for file discovery workflows.
#
# Reuse an existing executable when available. Otherwise, install fd through
# WinGet and verify its version output.
function Ensure-Fd {
    Ensure-Command `
        -Name "fd" `
        -Commands @("fd.exe", "fd") `
        -PackageId $packages.Fd `
        -VerifyArguments @("--version")
}

# Ensure fzf is installed and available for the fzf-lua Neovim plugin.
#
# The fzf executable is an external dependency; installing the Neovim plugin
# does not install fzf itself. Reuse an existing executable when available,
# otherwise install it through WinGet and verify its version.
function Ensure-Fzf {
    Ensure-Command `
        -Name "fzf" `
        -Commands @("fzf.exe", "fzf") `
        -PackageId $packages.Fzf `
        -VerifyArguments @("--version")
}

# Ensure the selected WinLibs GCC/G++ toolchain is available.
#
# WinGet may report an error when asked to install a package that is already
# installed. Therefore, locate the existing package before attempting an
# installation, and explicitly add its compiler directory to this process's
# PATH. Prefer WinLibs over another GCC installation found elsewhere on PATH.
#
# Set CC to the exact GCC executable. Tree-sitter parser builds can otherwise
# select cl.exe on Windows, even when GCC is installed and available on PATH.
# This setting affects this PowerShell process and its child processes only.
function Ensure-Compiler {
    Write-Status -Status INFO -Message "Locating the installed WinLibs toolchain..."

    if ([string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) {
        throw "LOCALAPPDATA is missing; cannot locate the WinLibs package."
    }

    $wingetPackagesRoot = Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Packages"

    if (-not (Test-Path -LiteralPath $wingetPackagesRoot -PathType Container)) {
        throw "WinGet's package directory was not found: $wingetPackagesRoot"
    }

    $packageDirectories = @(
        Get-ChildItem -LiteralPath $wingetPackagesRoot -Directory -ErrorAction Stop |
            Where-Object { $_.Name -like "BrechtSanders.WinLibs.POSIX.UCRT_*" }
    )

    if ($packageDirectories.Count -eq 0) {
        Invoke-WingetInstall -PackageId $packages.WinLibs

        $packageDirectories = @(
            Get-ChildItem -LiteralPath $wingetPackagesRoot -Directory -ErrorAction Stop |
                Where-Object { $_.Name -like "BrechtSanders.WinLibs.POSIX.UCRT_*" }
        )
    }

    if ($packageDirectories.Count -eq 0) {
        throw "WinLibs was not found in '$wingetPackagesRoot' after installation."
    }

    $compilerBin = $null

    foreach ($packageDirectory in $packageDirectories) {
        $candidate = Join-Path $packageDirectory.FullName "mingw64\bin"
        $gccCandidate = Join-Path $candidate "gcc.exe"
        $gxxCandidate = Join-Path $candidate "g++.exe"

        if (
            (Test-Path -LiteralPath $gccCandidate -PathType Leaf) -and
            (Test-Path -LiteralPath $gxxCandidate -PathType Leaf)
        ) {
            $compilerBin = $candidate
            break
        }
    }

    if (-not $compilerBin) {
        throw "WinLibs is installed, but gcc.exe and g++.exe could not be found together under its mingw64\bin directory."
    }

    $gccPath = Join-Path $compilerBin "gcc.exe"
    $gxxPath = Join-Path $compilerBin "g++.exe"

    # Put the selected WinLibs directory first and remove duplicate entries.
    $remainingEntries = @(
        $env:Path -split ";" |
            Where-Object {
                -not [string]::IsNullOrWhiteSpace($_) -and
                -not [string]::Equals(
                    $_.Trim().TrimEnd("\"),
                    $compilerBin.TrimEnd("\"),
                    [StringComparison]::OrdinalIgnoreCase
                )
            }
    )

    $env:Path = (@($compilerBin) + $remainingEntries) -join ";"

    # Verify that PATH resolves to the exact WinLibs executables.
    $gcc = Get-Application -Names @("gcc.exe", "gcc")
    $gxx = Get-Application -Names @("g++.exe", "g++")

    if (-not $gcc -or -not $gxx) {
        throw "WinLibs compiler executables exist, but GCC and G++ could not be resolved from PATH."
    }

    if (
        -not [string]::Equals(
            $gcc.Source,
            $gccPath,
            [StringComparison]::OrdinalIgnoreCase
        )
    ) {
        throw "GCC resolved to an unexpected executable: $($gcc.Source)"
    }

    if (
        -not [string]::Equals(
            $gxx.Source,
            $gxxPath,
            [StringComparison]::OrdinalIgnoreCase
        )
    ) {
        throw "G++ resolved to an unexpected executable: $($gxx.Source)"
    }

    $gccOutput = & $gcc.Source --version 2>&1
    $gccExitCode = $LASTEXITCODE

    if ($gccExitCode -ne 0) {
        throw "GCC verification failed (exit code $gccExitCode)."
    }

    $gccFirstLine = "$($gccOutput | Select-Object -First 1)"

    if ($gccFirstLine -notmatch 'GCC') {
        throw "GCC returned an unexpected version response: $gccFirstLine"
    }

    $gxxOutput = & $gxx.Source --version 2>&1
    $gxxExitCode = $LASTEXITCODE

    if ($gxxExitCode -ne 0) {
        throw "G++ verification failed (exit code $gxxExitCode)."
    }

    $gxxFirstLine = "$($gxxOutput | Select-Object -First 1)"

    if ($gxxFirstLine -notmatch 'G\+\+') {
        throw "G++ returned an unexpected version response: $gxxFirstLine"
    }

    # Configure the compiler explicitly for Tree-sitter child processes.
    $env:CC = $gccPath

    Write-Status -Status PASS -Message "GCC verified: $gccFirstLine"
    Write-Status -Status PASS -Message "G++ verified: $gxxFirstLine"
    Write-Status -Status INFO -Message "WinLibs compiler directory: $compilerBin"
    Write-Status -Status INFO -Message "CC configured for this process: $env:CC"
}

# Ensure the Tree-sitter CLI is available and meets the minimum version.
#
# The CLI is installed separately from the Neovim plugin and is required
# for building parser binaries.
function Ensure-TreeSitterCLI {
    $command = Get-Application -Names @("tree-sitter.exe", "tree-sitter")

    if (-not $command) {
        Invoke-WingetInstall -PackageId $packages.TreeSitter
        $command = Get-Application -Names @("tree-sitter.exe", "tree-sitter")
    }

    if (-not $command) {
        throw "tree-sitter was not found after installing $($packages.TreeSitter)."
    }

    $output = & $command.Source --version 2>&1
    $exitCode = $LASTEXITCODE

    if ($exitCode -ne 0) {
        throw "Tree-sitter CLI verification failed (exit code $exitCode)."
    }

    $versionLine = "$($output | Select-Object -First 1)"

    if ($versionLine -notmatch '^tree-sitter\s+(\d+\.\d+\.\d+)') {
        throw "Could not parse the Tree-sitter CLI version: $versionLine"
    }

    $version = [version]$Matches[1]

    if ($version -lt $minimumTreeSitterVersion) {
        throw "Tree-sitter CLI $version is too old; version $minimumTreeSitterVersion or later is required."
    }

    Write-Status -Status PASS -Message "Tree-sitter CLI $version meets the minimum requirement."
}

# Main entry point.
#
# Check platform and prerequisites first, then run core dependencies,
# providers, navigation and search tools, and development tools as independent
# steps. A failure in one step does not prevent the remaining independent
# steps from being checked.
try {
    Write-Host ""
    Write-Host "nvim-config — Windows dependency setup" -ForegroundColor Cyan
    Write-Host "======================================" -ForegroundColor Cyan

    if ($env:OS -ne "Windows_NT") {
        throw "This script supports Windows only."
    }

    Write-Status -Status PASS -Message "Windows platform detected."

    # Ensure System32 is available before resolving WinGet or other commands.
    Ensure-System32OnPath

    # WinGet is required for installing any missing managed dependencies.
    $null = Get-Winget
    Write-Status -Status PASS -Message "WinGet is available."

    # Core tools required by the configuration.
    Invoke-Step -Name "Checking core dependencies..." -Action {
        Ensure-Neovim

        Ensure-Command `
            -Name "Git" `
            -Commands @("git.exe", "git") `
            -PackageId $packages.Git `
            -VerifyArguments @("--version")

        Ensure-Curl
        Ensure-GitTar
    }

    # Set up the Node.js runtime and Neovim's npm provider package.
    Invoke-Step -Name "Setting up the Node.js provider..." -Action {
        Ensure-NodeProvider
    }

    # Set up Python and the pynvim package required by Neovim.
    Invoke-Step -Name "Setting up the Python 3 provider..." -Action {
        Ensure-PythonProvider
    }

    # Verify the external content-search tool used by native search workflows.
    Invoke-Step -Name "Checking ripgrep..." -Action {
        Ensure-Ripgrep
    }

    # Verify the external file-discovery tool used by navigation workflows.
    Invoke-Step -Name "Checking fd..." -Action {
        Ensure-Fd
    }

    # Verify the external fuzzy finder required by fzf-lua.
    Invoke-Step -Name "Checking fzf..." -Action {
        Ensure-Fzf
    }

    Invoke-Step -Name "Checking the WinLibs compiler toolchain..." -Action {
        Ensure-Compiler
    }

    Invoke-Step -Name "Checking the Tree-sitter CLI..." -Action {
        Ensure-TreeSitterCLI
    }

    # Verify the independent shell-script analysis tool.
    Invoke-Step -Name "Checking ShellCheck..." -Action {
        Ensure-ShellCheck
    }

    Write-Host ""

    # Summarize all failed steps so the user can resolve them and rerun.
    if ($script:Failed) {
        Write-Status -Status FAIL -Message "Dependency setup finished with one or more failures."

        foreach ($failure in $script:Failures) {
            Write-Host " - $failure" -ForegroundColor Red
        }
    }
    else {
        Write-Status -Status PASS -Message "All dependencies, providers, navigation and search tools, and development tools were verified."
    }

    # Explain the scope of PATH and compiler updates if applicable.
    if ($script:InstalledAnyPackage) {
        Write-Host "One or more WinGet packages were installed."
        Write-Host "PATH was refreshed for this PowerShell process."
        Write-Host "Restart already-running applications if they use an older environment."
    }

    Write-Host ""
}
catch {
    # Catch failures that occur outside the individual setup steps.
    $script:Failed = $true
    Write-Status -Status FAIL -Message $_.Exception.Message
}
finally {
    # Provide a consistent next step when the script exits unsuccessfully.
    if ($script:Failed) {
        Write-Host "Resolve the reported issues and rerun scripts/win-depend.ps1." -ForegroundColor Yellow
    }
}

# Return a process exit code suitable for automation and CI.
if ($script:Failed) {
    exit 1
}

exit 0
