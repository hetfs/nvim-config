
# Shared infrastructure and core Windows dependencies.
#
# This file is intended to be dot-sourced by win-depend.ps1.
# Dot-sourcing defines functions only. It does not install or verify anything.
#
# Explicit entry point:
#   Initialize-WinDependCore
#
# Shared state:
#   Get-WinDependState
#
# Core dependencies:
#   - Windows
#   - WinGet
#   - Git for Windows
#   - WinGet-managed cURL
#   - Git for Windows GNU tar

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# Package identifiers
# ---------------------------------------------------------------------------

$script:WinDependPackages = @{
    Neovim    = "Neovim.Neovim"
    Git       = "Git.Git"
    Curl      = "cURL.cURL"
    Node      = "OpenJS.NodeJS"
    Python    = "Python.Python.3.14"
    ShellCheck = "koalaman.shellcheck"
    Ripgrep   = "BurntSushi.ripgrep.MSVC"
    Fd        = "sharkdp.fd"
    Fzf       = "junegunn.fzf"
    WinLibs   = "BrechtSanders.WinLibs.POSIX.UCRT"
    TreeSitter = "tree-sitter.tree-sitter-cli"
}

# Shared state is initialized by Initialize-WinDependCore.
$script:WinDependState = $null

# ---------------------------------------------------------------------------
# Status reporting
# ---------------------------------------------------------------------------

function Write-Status {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet("INFO", "OK", "WARN", "ERROR")]
        [string] $Level,

        [Parameter(Mandatory)]
        [string] $Message
    )

    $color = switch ($Level) {
        "INFO"  { "Cyan" }
        "OK"    { "Green" }
        "WARN"  { "Yellow" }
        "ERROR" { "Red" }
    }

    Write-Host "[$Level] $Message" -ForegroundColor $color
}

# ---------------------------------------------------------------------------
# Shared state
# ---------------------------------------------------------------------------

function Initialize-WinDependState {
    [CmdletBinding()]
    param()

    $script:WinDependState = [PSCustomObject]@{
        Initialized         = $false
        Failed              = $false
        InstalledAnyPackage = $false
        Failures            = [System.Collections.Generic.List[string]]::new()
    }

    return $script:WinDependState
}

function Get-WinDependState {
    [CmdletBinding()]
    param()

    if ($null -eq $script:WinDependState) {
        throw "Shared dependency state has not been initialized. Run Initialize-WinDependCore first."
    }

    return $script:WinDependState
}

# ---------------------------------------------------------------------------
# Independent step execution
# ---------------------------------------------------------------------------

function Invoke-Step {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Name,

        [Parameter(Mandatory)]
        [scriptblock] $Action
    )

    Write-Status -Level INFO -Message $Name

    try {
        & $Action
        Write-Status -Level OK -Message "$Name completed."
        return $true
    }
    catch {
        $message = "$Name`: $($_.Exception.Message)"

        Write-Status -Level ERROR -Message $message

        if ($null -ne $script:WinDependState) {
            $script:WinDependState.Failed = $true
            $script:WinDependState.Failures.Add($message)
        }

        return $false
    }
}

# ---------------------------------------------------------------------------
# Application discovery
# ---------------------------------------------------------------------------

function Get-Application {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Name
    )

    $application = Get-Command `
        -Name $Name `
        -CommandType Application `
        -ErrorAction SilentlyContinue |
        Select-Object -First 1

    if ($null -eq $application) {
        return $null
    }

    return $application.Source
}

function Ensure-System32OnPath {
    [CmdletBinding()]
    param()

    $system32 = Join-Path $env:SystemRoot "System32"

    if (-not (Test-Path -LiteralPath $system32 -PathType Container)) {
        throw "Windows System32 directory was not found: $system32"
    }

    $pathEntries = @(
        $env:Path -split [IO.Path]::PathSeparator |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    )

    $exists = $false

    foreach ($entry in $pathEntries) {
        if ([string]::Equals(
            $entry.TrimEnd("\"),
            $system32.TrimEnd("\"),
            [StringComparison]::OrdinalIgnoreCase
        )) {
            $exists = $true
            break
        }
    }

    if (-not $exists) {
        $env:Path = "$system32$([IO.Path]::PathSeparator)$env:Path"
    }
}

function Refresh-ProcessPath {
    [CmdletBinding()]
    param()

    # Preserve the current process PATH first. This retains process-scoped
    # changes made by earlier dependency modules.

    $entries = [System.Collections.Generic.List[string]]::new()
    $seen = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::OrdinalIgnoreCase
    )

    $currentPath = @(
        $env:Path -split [IO.Path]::PathSeparator |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    )

    $machinePath = @(
        [Environment]::GetEnvironmentVariable("Path", "Machine") -split [IO.Path]::PathSeparator |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    )

    $userPath = @(
        [Environment]::GetEnvironmentVariable("Path", "User") -split [IO.Path]::PathSeparator |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    )

    foreach ($entry in @($currentPath) + @($machinePath) + @($userPath)) {
        $normalized = $entry.Trim().Trim('"').TrimEnd("\")

        if ([string]::IsNullOrWhiteSpace($normalized)) {
            continue
        }

        if ($seen.Add($normalized)) {
            $entries.Add($normalized)
        }
    }

    $env:Path = $entries -join [IO.Path]::PathSeparator

    Ensure-System32OnPath
}

# ---------------------------------------------------------------------------
# WinGet
# ---------------------------------------------------------------------------

function Get-Winget {
    [CmdletBinding()]
    param()

    $wingetPath = Get-Application -Name "winget.exe"

    if ([string]::IsNullOrWhiteSpace($wingetPath)) {
        throw "WinGet was not found. Install or repair the App Installer package."
    }

    return $wingetPath
}

function Invoke-WingetInstall {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $PackageId
    )

    $winget = Get-Winget

    Write-Status -Level INFO -Message "Installing WinGet package: $PackageId"

    & $winget install `
        --id $PackageId `
        --exact `
        --accept-source-agreements `
        --accept-package-agreements `
        --silent

    if ($LASTEXITCODE -ne 0) {
        throw "WinGet installation failed for '$PackageId' with exit code $LASTEXITCODE."
    }

    $state = Get-WinDependState
    $state.InstalledAnyPackage = $true

    Refresh-ProcessPath
}

function Ensure-Command {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Name,

        [Parameter(Mandatory)]
        [string] $PackageId
    )

    $application = Get-Application -Name $Name

    if ($null -eq $application) {
        Invoke-WingetInstall -PackageId $PackageId
        Refresh-ProcessPath

        $application = Get-Application -Name $Name
    }

    if ($null -eq $application) {
        throw "Required command '$Name' is still unavailable after installing '$PackageId'."
    }

    return $application
}

# ---------------------------------------------------------------------------
# Git for Windows
# ---------------------------------------------------------------------------

function Ensure-Git {
    [CmdletBinding()]
    param()

    $gitPath = Ensure-Command `
        -Name "git.exe" `
        -PackageId $script:WinDependPackages.Git

    $versionOutput = & $gitPath --version 2>&1

    if ($LASTEXITCODE -ne 0 -or "$versionOutput" -notmatch "^git version\s+") {
        throw "Git was found but could not be verified. Executable: $gitPath"
    }

    Write-Status -Level OK -Message "Git verified: $versionOutput"

    return $gitPath
}

# ---------------------------------------------------------------------------
# WinGet-managed cURL
# ---------------------------------------------------------------------------

function Ensure-Curl {
    [CmdletBinding()]
    param()

    $curlPath = Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Links\curl.exe"

    if (-not (Test-Path -LiteralPath $curlPath -PathType Leaf)) {
        Invoke-WingetInstall -PackageId $script:WinDependPackages.Curl
        Refresh-ProcessPath
    }

    if (-not (Test-Path -LiteralPath $curlPath -PathType Leaf)) {
        throw "WinGet-managed cURL was not found at the expected path: $curlPath"
    }

    $versionOutput = & $curlPath --version 2>&1

    if ($LASTEXITCODE -ne 0 -or "$versionOutput" -notmatch "^curl\s+") {
        throw "The cURL executable could not be verified: $curlPath"
    }

    Write-Status -Level OK -Message "WinGet-managed cURL verified: $curlPath"

    return $curlPath
}

# ---------------------------------------------------------------------------
# Git for Windows GNU tar
# ---------------------------------------------------------------------------

function Ensure-GitTar {
    [CmdletBinding()]
    param()

    $gitPath = Get-Application -Name "git.exe"

    if ([string]::IsNullOrWhiteSpace($gitPath)) {
        throw "Git must be available before Git for Windows GNU tar can be verified."
    }

    $gitDirectory = Split-Path -Parent $gitPath
    $gitDirectoryName = Split-Path -Leaf $gitDirectory

    if ($gitDirectoryName -ieq "cmd") {
        $gitRoot = Split-Path -Parent $gitDirectory
    }
    else {
        throw "Cannot determine the Git for Windows installation root from: $gitPath"
    }

    $gitUsrBin = Join-Path $gitRoot "usr\bin"
    $tarPath = Join-Path $gitUsrBin "tar.exe"

    if (-not (Test-Path -LiteralPath $tarPath -PathType Leaf)) {
        throw "Git for Windows GNU tar was not found: $tarPath"
    }

    # Put Git's GNU utilities ahead of other tar installations for this
    # process only. This does not modify the user's persistent PATH.

    $existingEntries = @(
        $env:Path -split [IO.Path]::PathSeparator |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    )

    $remainingEntries = @(
        $existingEntries | Where-Object {
            -not [string]::Equals(
                $_.Trim().Trim('"').TrimEnd("\"),
                $gitUsrBin.TrimEnd("\"),
                [StringComparison]::OrdinalIgnoreCase
            )
        }
    )

    $env:Path = @($gitUsrBin) + $remainingEntries -join [IO.Path]::PathSeparator

    $versionOutput = & $tarPath --version 2>&1

    if ($LASTEXITCODE -ne 0 -or "$versionOutput" -notmatch "^tar \(GNU tar\)") {
        throw "The Git for Windows tar executable is not GNU tar: $tarPath"
    }

    $resolvedTar = Get-Application -Name "tar.exe"

    if (-not [string]::Equals(
        $resolvedTar,
        $tarPath,
        [StringComparison]::OrdinalIgnoreCase
    )) {
        throw "GNU tar is installed, but PATH does not resolve to the Git for Windows executable. Resolved: $resolvedTar"
    }

    Write-Status -Level OK -Message "Git for Windows GNU tar verified: $tarPath"

    return $tarPath
}

# ---------------------------------------------------------------------------
# Core initialization
# ---------------------------------------------------------------------------

function Initialize-WinDependCore {
    [CmdletBinding()]
    param()

    Initialize-WinDependState | Out-Null

    Write-Status -Level INFO -Message "Initializing shared Windows dependency infrastructure."

    if ($env:OS -ne "Windows_NT") {
        throw "This dependency provisioner supports Windows only."
    }

    Ensure-System32OnPath

    # WinGet is required by the installation helpers. Fail initialization
    # immediately if it is unavailable.

    $wingetPath = Get-Winget
    Write-Status -Level OK -Message "WinGet verified: $wingetPath"

    # Each core dependency is checked independently. A failure in one
    # dependency does not prevent the remaining checks from running.

    Invoke-Step -Name "Verify Git for Windows" -Action {
        Ensure-Git | Out-Null
    } | Out-Null

    Invoke-Step -Name "Verify WinGet-managed cURL" -Action {
        Ensure-Curl | Out-Null
    } | Out-Null

    Invoke-Step -Name "Verify Git for Windows GNU tar" -Action {
        Ensure-GitTar | Out-Null
    } | Out-Null

    $state = Get-WinDependState
    $state.Initialized = $true

    if ($state.Failed) {
        Write-Status -Level WARN -Message "Core initialization completed with one or more failures."
    }
    else {
        Write-Status -Level OK -Message "Core initialization completed successfully."
    }

    return $state
}
