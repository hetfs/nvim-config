# Provision and configure external tools used by the Neovim configuration.
#
# This file is intended to be dot-sourced by win-depend.ps1.
# Dot-sourcing defines functions only. It does not install anything.
#
# Explicit entry point:
#   Initialize-WinDependExternal
#
# Optional parameters:
#   -CheckOnly          Verify dependencies without installing or changing PATH.
#   -ConfigurePathOnly  Configure PATH without installing dependencies.
#   -SkipPath           Do not configure PATH.
#
# External tools:
#   - Tectonic
#   - Ghostscript
#   - ImageMagick
#   - Mermaid CLI
#   - GitHub CLI
#
# Requirements:
#   - Shared infrastructure from win-core.ps1
#   - Node.js and npm for Mermaid CLI
#   - WinGet for ImageMagick and GitHub CLI

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

$script:WinDependExternalConfig = @{
    Tectonic = @{
        Version          = '0.17.0'
        InstallDirectory = Join-Path $env:LOCALAPPDATA 'Programs\Tectonic'
        Executable       = 'tectonic.exe'
    }

    Ghostscript = @{
        Version       = '10.08.0'
        InstallDirectory = 'C:\Program Files\gs\gs10.08.0'
        InstallerName = 'gs10080w64.exe'
        DownloadUrl   = 'https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/download/gs10080/gs10080w64.exe'
        SHA256        = '52a91b8bf09298788d7a57b9206127026c23eacd75405f0a131e26dc381dce50'
    }

    ImageMagick = @{
        PackageId = 'ImageMagick.Q16-HDRI'
    }

    Mermaid = @{
        PackageName = '@mermaid-js/mermaid-cli'
    }

    GitHubCli = @{
        PackageId  = 'GitHub.cli'
        Executable = 'gh.exe'
    }
}

# ---------------------------------------------------------------------------
# Shared state and logging
# ---------------------------------------------------------------------------

function Get-WinDependExternalState {
    $state = Get-WinDependState

    if ($null -eq $state) {
        throw 'Shared WinDepend state is unavailable. Initialize win-core.ps1 first.'
    }

    return $state
}

function Set-WinDependExternalStateProperty {
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [AllowNull()]
        [object]$Value
    )

    $state = Get-WinDependExternalState
    $property = $state.PSObject.Properties[$Name]

    if ($null -eq $property) {
        $state | Add-Member -MemberType NoteProperty -Name $Name -Value $Value
    }
    else {
        $state.$Name = $Value
    }
}

function Write-WinDependExternalStatus {
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [ValidateSet('INFO', 'OK', 'WARN', 'ERROR')]
        [string]$Level = 'INFO'
    )

    $color = switch ($Level) {
        'INFO'  { 'Cyan' }
        'OK'    { 'Green' }
        'WARN'  { 'Yellow' }
        'ERROR' { 'Red' }
    }

    Write-Host "[$Level] $Message" -ForegroundColor $color
}

function Clear-WinDependExternalFailures {
    $state = Get-WinDependExternalState

    if ($null -eq $state.Failures) {
        return
    }

    $externalFailurePattern = '^(Tectonic|Ghostscript|ImageMagick|Mermaid CLI|GitHub CLI|External tool PATH configuration):'

    $remainingFailures = @(
        $state.Failures | Where-Object {
            $_ -notmatch $externalFailurePattern
        }
    )

    $state.Failures.Clear()

    foreach ($failure in $remainingFailures) {
        [void]$state.Failures.Add([string]$failure)
    }

    $state.Failed = ($state.Failures.Count -gt 0)
}

function Update-WinDependExternalFailureState {
    $state = Get-WinDependExternalState
    $state.Failed = ($state.Failures.Count -gt 0)
}

function Set-WinDependExternalInstalledState {
    Set-WinDependExternalStateProperty -Name 'InstalledAnyPackage' -Value $true
}

# ---------------------------------------------------------------------------
# PATH management
# ---------------------------------------------------------------------------

function Add-WinDependExternalPath {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        return $false
    }

    $normalizedPath = [System.IO.Path]::GetFullPath($Path).TrimEnd('\')

    $userPath = [Environment]::GetEnvironmentVariable(
        'Path',
        [EnvironmentVariableTarget]::User
    )

    $userEntries = @(
        $userPath -split ';' |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    )

    $alreadyPresent = $false

    foreach ($entry in $userEntries) {
        try {
            $normalizedEntry = [System.IO.Path]::GetFullPath($entry).TrimEnd('\')

            if ($normalizedEntry -ieq $normalizedPath) {
                $alreadyPresent = $true
                break
            }
        }
        catch {
            continue
        }
    }

    if (-not $alreadyPresent) {
        $newUserPath = @($userEntries + $normalizedPath) -join ';'

        [Environment]::SetEnvironmentVariable(
            'Path',
            $newUserPath,
            [EnvironmentVariableTarget]::User
        )

        Write-WinDependExternalStatus "Added to user PATH: $normalizedPath" 'OK'
    }

    $processEntries = @(
        $env:Path -split ';' |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    )

    $processAlreadyPresent = $false

    foreach ($entry in $processEntries) {
        try {
            $normalizedEntry = [System.IO.Path]::GetFullPath($entry).TrimEnd('\')

            if ($normalizedEntry -ieq $normalizedPath) {
                $processAlreadyPresent = $true
                break
            }
        }
        catch {
            continue
        }
    }

    if (-not $processAlreadyPresent) {
        $env:Path = "$env:Path;$normalizedPath"
    }

    return $true
}

function Set-WinDependExternalPath {
    $config = $script:WinDependExternalConfig

    $paths = @(
        $config.Tectonic.InstallDirectory
        (Join-Path $config.Ghostscript.InstallDirectory 'bin')
    )

    foreach ($path in $paths) {
        if (Test-Path -LiteralPath $path -PathType Container) {
            [void](Add-WinDependExternalPath -Path $path)
        }
    }
}

# ---------------------------------------------------------------------------
# Tectonic
# ---------------------------------------------------------------------------

function Get-WinDependExternalTectonicPath {
    $config = $script:WinDependExternalConfig.Tectonic
    $expectedPath = Join-Path $config.InstallDirectory $config.Executable

    if (Test-Path -LiteralPath $expectedPath -PathType Leaf) {
        return $expectedPath
    }

    $command = Get-Command 'tectonic.exe' -ErrorAction SilentlyContinue

    if ($null -ne $command) {
        return $command.Source
    }

    return $null
}

function Install-WinDependExternalTectonic {
    $config = $script:WinDependExternalConfig.Tectonic

    $existingPath = Get-WinDependExternalTectonicPath

    if ($existingPath) {
        Write-WinDependExternalStatus "Tectonic is already installed: $existingPath" 'OK'
        return $existingPath
    }

    $version = $config.Version
    $archiveName = "tectonic-$version-x86_64-pc-windows-msvc.zip"
    $downloadUrl = "https://github.com/tectonic-typesetting/tectonic/releases/download/tectonic@$version/$archiveName"

    $temporaryDirectory = Join-Path (
        [System.IO.Path]::GetTempPath()
    ) ("win-depend-tectonic-" + [guid]::NewGuid().ToString('N'))

    New-Item -ItemType Directory -Path $temporaryDirectory -Force |
        Out-Null

    try {
        $archivePath = Join-Path $temporaryDirectory $archiveName
        $extractDirectory = Join-Path $temporaryDirectory 'extracted'

        Write-WinDependExternalStatus "Downloading Tectonic $version."

        Invoke-WebRequest `
            -Uri $downloadUrl `
            -OutFile $archivePath `
            -ErrorAction Stop

        if (-not (Test-Path -LiteralPath $archivePath -PathType Leaf)) {
            throw 'The Tectonic release archive was not downloaded.'
        }

        Write-WinDependExternalStatus 'Extracting Tectonic archive.'

        Expand-Archive `
            -LiteralPath $archivePath `
            -DestinationPath $extractDirectory `
            -Force

        $tectonicExecutable = Get-ChildItem `
            -LiteralPath $extractDirectory `
            -Filter 'tectonic.exe' `
            -File `
            -Recurse |
            Select-Object -First 1

        if ($null -eq $tectonicExecutable) {
            throw 'The Tectonic archive does not contain tectonic.exe.'
        }

        New-Item `
            -ItemType Directory `
            -Path $config.InstallDirectory `
            -Force |
            Out-Null

        $destination = Join-Path $config.InstallDirectory $config.Executable

        Copy-Item `
            -LiteralPath $tectonicExecutable.FullName `
            -Destination $destination `
            -Force

        if (-not (Test-Path -LiteralPath $destination -PathType Leaf)) {
            throw "Tectonic could not be installed at $destination."
        }

        Set-WinDependExternalInstalledState

        Write-WinDependExternalStatus "Tectonic installed: $destination" 'OK'

        return $destination
    }
    finally {
        Remove-Item `
            -LiteralPath $temporaryDirectory `
            -Recurse `
            -Force `
            -ErrorAction SilentlyContinue
    }
}

function Test-WinDependExternalTectonic {
    $executable = Get-WinDependExternalTectonicPath

    if (-not $executable) {
        throw 'Tectonic was not found.'
    }

    $versionOutput = & $executable --version 2>&1

    if ($LASTEXITCODE -ne 0) {
        throw 'Tectonic version check failed.'
    }

    $version = ($versionOutput | Select-Object -Last 1).ToString().Trim()

    Write-WinDependExternalStatus "Tectonic: $version" 'OK'

    Set-WinDependExternalStateProperty -Name 'TectonicPath' -Value $executable
    Set-WinDependExternalStateProperty -Name 'TectonicVersion' -Value $version

    return $executable
}

# ---------------------------------------------------------------------------
# Ghostscript
# ---------------------------------------------------------------------------

function Get-WinDependExternalGhostscriptPath {
    $config = $script:WinDependExternalConfig.Ghostscript

    $expectedPath = Join-Path `
        (Join-Path $config.InstallDirectory 'bin') `
        'gswin64c.exe'

    if (Test-Path -LiteralPath $expectedPath -PathType Leaf) {
        return $expectedPath
    }

    $command = Get-Command 'gswin64c.exe' -ErrorAction SilentlyContinue

    if ($null -ne $command) {
        return $command.Source
    }

    return $null
}

function Install-WinDependExternalGhostscript {
    $config = $script:WinDependExternalConfig.Ghostscript

    $existingPath = Get-WinDependExternalGhostscriptPath

    if ($existingPath) {
        Write-WinDependExternalStatus "Ghostscript is already installed: $existingPath" 'OK'
        return $existingPath
    }

    $temporaryDirectory = Join-Path (
        [System.IO.Path]::GetTempPath()
    ) ("win-depend-ghostscript-" + [guid]::NewGuid().ToString('N'))

    New-Item -ItemType Directory -Path $temporaryDirectory -Force |
        Out-Null

    try {
        $installerPath = Join-Path $temporaryDirectory $config.InstallerName

        Write-WinDependExternalStatus "Downloading Ghostscript $($config.Version)."

        Invoke-WebRequest `
            -Uri $config.DownloadUrl `
            -OutFile $installerPath `
            -ErrorAction Stop

        if (-not (Test-Path -LiteralPath $installerPath -PathType Leaf)) {
            throw 'The Ghostscript installer was not downloaded.'
        }

        $actualHash = (
            Get-FileHash -LiteralPath $installerPath -Algorithm SHA256
        ).Hash

        if ($actualHash -ne $config.SHA256) {
            throw "Ghostscript installer SHA256 mismatch. Expected $($config.SHA256), received $actualHash."
        }

        Write-WinDependExternalStatus 'Ghostscript installer SHA256 verified.' 'OK'

        $confirmation = Read-Host "Install Ghostscript $($config.Version)? This requires administrator privileges. [y/N]"

        if ($confirmation -notmatch '^(y|yes)$') {
            throw 'Ghostscript installation was declined.'
        }

        Write-WinDependExternalStatus 'Starting the Ghostscript installer.'

        $process = Start-Process `
            -FilePath $installerPath `
            -ArgumentList '/S' `
            -Wait `
            -PassThru

        if ($process.ExitCode -ne 0) {
            throw "Ghostscript installer exited with code $($process.ExitCode)."
        }

        $installedPath = Get-WinDependExternalGhostscriptPath

        if (-not $installedPath) {
            throw 'Ghostscript installation completed, but gswin64c.exe was not found.'
        }

        Set-WinDependExternalInstalledState

        Write-WinDependExternalStatus "Ghostscript installed: $installedPath" 'OK'

        return $installedPath
    }
    finally {
        Remove-Item `
            -LiteralPath $temporaryDirectory `
            -Recurse `
            -Force `
            -ErrorAction SilentlyContinue
    }
}

function New-WinDependExternalGhostscriptShim {
    param(
        [Parameter(Mandatory)]
        [string]$ExecutablePath
    )

    $shimDirectory = Join-Path $HOME '.local\bin'
    $shimPath = Join-Path $shimDirectory 'gs.cmd'

    New-Item -ItemType Directory -Path $shimDirectory -Force |
        Out-Null

    $shimContent = @"
@echo off
"$ExecutablePath" %*
exit /b %ERRORLEVEL%
"@

    Set-Content `
        -LiteralPath $shimPath `
        -Value $shimContent `
        -Encoding ASCII

    if (-not (Test-Path -LiteralPath $shimPath -PathType Leaf)) {
        throw "Ghostscript compatibility shim could not be created: $shimPath"
    }

    Write-WinDependExternalStatus "Ghostscript compatibility command created: $shimPath" 'OK'

    Set-WinDependExternalStateProperty -Name 'GhostscriptShimPath' -Value $shimPath

    return $shimPath
}

function Test-WinDependExternalGhostscript {
    $executable = Get-WinDependExternalGhostscriptPath

    if (-not $executable) {
        throw 'Ghostscript was not found.'
    }

    $versionOutput = & $executable -version 2>&1

    if ($LASTEXITCODE -ne 0) {
        throw 'Ghostscript version check failed.'
    }

    $version = ($versionOutput | Select-Object -First 1).ToString().Trim()

    Write-WinDependExternalStatus "Ghostscript: $version" 'OK'

    Set-WinDependExternalStateProperty -Name 'GhostscriptPath' -Value $executable
    Set-WinDependExternalStateProperty -Name 'GhostscriptVersion' -Value $version

    [void](New-WinDependExternalGhostscriptShim -ExecutablePath $executable)

    return $executable
}

# ---------------------------------------------------------------------------
# ImageMagick
# ---------------------------------------------------------------------------

function Get-WinDependExternalImageMagickPath {
    $command = Get-Command 'magick.exe' -ErrorAction SilentlyContinue

    if ($null -ne $command) {
        return $command.Source
    }

    return $null
}

function Install-WinDependExternalImageMagick {
    $config = $script:WinDependExternalConfig.ImageMagick

    $existingPath = Get-WinDependExternalImageMagickPath

    if ($existingPath) {
        Write-WinDependExternalStatus "ImageMagick is already installed: $existingPath" 'OK'
        return $existingPath
    }

    $winget = Get-Winget

    if (-not $winget) {
        throw 'WinGet is not available. ImageMagick cannot be installed.'
    }

    Write-WinDependExternalStatus 'Installing ImageMagick through WinGet.'

    & $winget install `
        --id $config.PackageId `
        --exact `
        --silent `
        --accept-package-agreements `
        --accept-source-agreements

    if ($LASTEXITCODE -ne 0) {
        throw "WinGet failed to install ImageMagick. Exit code: $LASTEXITCODE"
    }

    Refresh-ProcessPath

    $installedPath = Get-WinDependExternalImageMagickPath

    if (-not $installedPath) {
        throw 'ImageMagick installation completed, but magick.exe was not found on PATH.'
    }

    Set-WinDependExternalInstalledState

    Write-WinDependExternalStatus "ImageMagick installed: $installedPath" 'OK'

    return $installedPath
}

function Test-WinDependExternalImageMagick {
    $executable = Get-WinDependExternalImageMagickPath

    if (-not $executable) {
        throw 'ImageMagick was not found.'
    }

    $versionOutput = & $executable -version 2>&1

    if ($LASTEXITCODE -ne 0) {
        throw 'ImageMagick version check failed.'
    }

    $version = ($versionOutput | Select-Object -First 1).ToString().Trim()

    Write-WinDependExternalStatus "ImageMagick: $version" 'OK'

    Set-WinDependExternalStateProperty -Name 'ImageMagickPath' -Value $executable
    Set-WinDependExternalStateProperty -Name 'ImageMagickVersion' -Value $version

    return $executable
}

# ---------------------------------------------------------------------------
# Mermaid CLI
# ---------------------------------------------------------------------------

function Get-WinDependExternalMermaidPath {
    $command = Get-Command 'mmdc.cmd' -ErrorAction SilentlyContinue

    if ($null -ne $command) {
        return $command.Source
    }

    $command = Get-Command 'mmdc' -ErrorAction SilentlyContinue

    if ($null -ne $command) {
        return $command.Source
    }

    return $null
}

function Install-WinDependExternalMermaid {
    $config = $script:WinDependExternalConfig.Mermaid

    $existingPath = Get-WinDependExternalMermaidPath

    if ($existingPath) {
        Write-WinDependExternalStatus "Mermaid CLI is already installed: $existingPath" 'OK'
        return $existingPath
    }

    $npm = Get-Command 'npm.cmd' -ErrorAction SilentlyContinue

    if ($null -eq $npm) {
        $npm = Get-Command 'npm' -ErrorAction SilentlyContinue
    }

    if ($null -eq $npm) {
        throw 'npm was not found. Install and initialize the Node.js module first.'
    }

    Write-WinDependExternalStatus 'Installing Mermaid CLI globally through npm.'

    & $npm.Source install --global $config.PackageName

    if ($LASTEXITCODE -ne 0) {
        throw "npm failed to install Mermaid CLI. Exit code: $LASTEXITCODE"
    }

    Refresh-ProcessPath

    $installedPath = Get-WinDependExternalMermaidPath

    if (-not $installedPath) {
        throw 'Mermaid CLI installation completed, but mmdc was not found on PATH.'
    }

    Set-WinDependExternalInstalledState

    Write-WinDependExternalStatus "Mermaid CLI installed: $installedPath" 'OK'

    return $installedPath
}

function Test-WinDependExternalMermaid {
    $executable = Get-WinDependExternalMermaidPath

    if (-not $executable) {
        throw 'Mermaid CLI was not found.'
    }

    $versionOutput = & $executable --version 2>&1

    if ($LASTEXITCODE -ne 0) {
        throw 'Mermaid CLI version check failed.'
    }

    $version = ($versionOutput | Select-Object -Last 1).ToString().Trim()

    Write-WinDependExternalStatus "Mermaid CLI version: $version" 'OK'

    Set-WinDependExternalStateProperty -Name 'MermaidPath' -Value $executable
    Set-WinDependExternalStateProperty -Name 'MermaidVersion' -Value $version

    return $executable
}

# ---------------------------------------------------------------------------
# GitHub CLI
# ---------------------------------------------------------------------------

function Get-WinDependExternalGitHubCliPath {
    $command = Get-Command 'gh.exe' -ErrorAction SilentlyContinue

    if ($null -eq $command) {
        $command = Get-Command 'gh' -ErrorAction SilentlyContinue
    }

    if ($null -ne $command) {
        return $command.Source
    }

    $candidates = @(
        (Join-Path $env:LOCALAPPDATA 'Programs\GitHub CLI\gh.exe')
        (Join-Path $env:ProgramFiles 'GitHub CLI\gh.exe')
    )

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return $candidate
        }
    }

    return $null
}

function Install-WinDependExternalGitHubCli {
    $config = $script:WinDependExternalConfig.GitHubCli

    $existingPath = Get-WinDependExternalGitHubCliPath

    if ($existingPath) {
        Write-WinDependExternalStatus "GitHub CLI is already installed: $existingPath" 'OK'
        return $existingPath
    }

    $winget = Get-Winget

    if (-not $winget) {
        throw 'WinGet is not available. GitHub CLI cannot be installed.'
    }

    Write-WinDependExternalStatus 'Installing GitHub CLI through WinGet.'

    & $winget install `
        --id $config.PackageId `
        --exact `
        --silent `
        --accept-package-agreements `
        --accept-source-agreements

    if ($LASTEXITCODE -ne 0) {
        throw "WinGet failed to install GitHub CLI. Exit code: $LASTEXITCODE"
    }

    Refresh-ProcessPath

    $installedPath = Get-WinDependExternalGitHubCliPath

    if (-not $installedPath) {
        throw 'GitHub CLI installation completed, but gh.exe was not found.'
    }

    Set-WinDependExternalInstalledState

    Write-WinDependExternalStatus "GitHub CLI installed: $installedPath" 'OK'

    return $installedPath
}

function Test-WinDependExternalGitHubCli {
    $executable = Get-WinDependExternalGitHubCliPath

    if (-not $executable) {
        throw 'GitHub CLI was not found.'
    }

    $versionOutput = & $executable --version 2>&1

    if ($LASTEXITCODE -ne 0) {
        throw 'GitHub CLI version check failed.'
    }

    $version = ($versionOutput | Select-Object -First 1).ToString().Trim()

    if ($version -notmatch '^gh version\s+(\d+\.\d+\.\d+)') {
        throw "Unable to determine GitHub CLI version: $version"
    }

    $versionNumber = $Matches[1]

    Write-WinDependExternalStatus "GitHub CLI: $version" 'OK'

    Set-WinDependExternalStateProperty -Name 'GitHubCliPath' -Value $executable
    Set-WinDependExternalStateProperty -Name 'GitHubCliVersion' -Value $versionNumber

    return $executable
}

# ---------------------------------------------------------------------------
# Individual initialization steps
#
# Invoke-Step in win-core.ps1 owns step-level logging.
# These functions therefore only report tool-specific activity.
# ---------------------------------------------------------------------------

function Initialize-WinDependExternalTectonic {
    param(
        [switch]$CheckOnly
    )

    $executable = Get-WinDependExternalTectonicPath

    if (-not $executable) {
        if ($CheckOnly) {
            throw 'Tectonic is not installed.'
        }

        Write-WinDependExternalStatus 'Tectonic is not installed.'

        $confirmation = Read-Host 'Install Tectonic now? [y/N]'

        if ($confirmation -notmatch '^(y|yes)$') {
            throw 'Tectonic installation was declined.'
        }

        [void](Install-WinDependExternalTectonic)
    }

    [void](Test-WinDependExternalTectonic)
}

function Initialize-WinDependExternalGhostscript {
    param(
        [switch]$CheckOnly
    )

    $executable = Get-WinDependExternalGhostscriptPath

    if (-not $executable) {
        if ($CheckOnly) {
            throw 'Ghostscript is not installed.'
        }

        [void](Install-WinDependExternalGhostscript)
    }

    [void](Test-WinDependExternalGhostscript)
}

function Initialize-WinDependExternalImageMagick {
    param(
        [switch]$CheckOnly
    )

    $executable = Get-WinDependExternalImageMagickPath

    if (-not $executable) {
        if ($CheckOnly) {
            throw 'ImageMagick is not installed.'
        }

        [void](Install-WinDependExternalImageMagick)
    }

    [void](Test-WinDependExternalImageMagick)
}

function Initialize-WinDependExternalMermaid {
    param(
        [switch]$CheckOnly
    )

    $executable = Get-WinDependExternalMermaidPath

    if (-not $executable) {
        if ($CheckOnly) {
            throw 'Mermaid CLI is not installed.'
        }

        [void](Install-WinDependExternalMermaid)
    }

    [void](Test-WinDependExternalMermaid)
}

function Initialize-WinDependExternalGitHubCli {
    param(
        [switch]$CheckOnly
    )

    $executable = Get-WinDependExternalGitHubCliPath

    if (-not $executable) {
        if ($CheckOnly) {
            throw 'GitHub CLI is not installed.'
        }

        [void](Install-WinDependExternalGitHubCli)
    }

    [void](Test-WinDependExternalGitHubCli)
}

function Initialize-WinDependExternalPath {
    Set-WinDependExternalPath
}

# ---------------------------------------------------------------------------
# Main entry point
# ---------------------------------------------------------------------------

function Initialize-WinDependExternal {
    [CmdletBinding()]
    param(
        [switch]$CheckOnly,

        [switch]$ConfigurePathOnly,

        [switch]$SkipPath
    )

    if ($CheckOnly -and $ConfigurePathOnly) {
        throw 'CheckOnly and ConfigurePathOnly cannot be used together.'
    }

    $state = Get-WinDependExternalState

    if (-not $state.Initialized) {
        throw 'WinDepend core has not been initialized. Run Initialize-WinDependCore first.'
    }

    Clear-WinDependExternalFailures

    # Configure PATH only. No dependency installation or verification.
    if ($ConfigurePathOnly) {
        if (-not $SkipPath) {
            Invoke-Step -Name 'External tool PATH configuration' -Action {
                Initialize-WinDependExternalPath
            } | Out-Null
        }

        Update-WinDependExternalFailureState
        return $state
    }

    # Check-only mode never installs tools or modifies PATH.
    if ($CheckOnly) {
        Invoke-Step -Name 'Tectonic' -Action {
            Initialize-WinDependExternalTectonic -CheckOnly
        } | Out-Null

        Invoke-Step -Name 'Ghostscript' -Action {
            Initialize-WinDependExternalGhostscript -CheckOnly
        } | Out-Null

        Invoke-Step -Name 'ImageMagick' -Action {
            Initialize-WinDependExternalImageMagick -CheckOnly
        } | Out-Null

        Invoke-Step -Name 'Mermaid CLI' -Action {
            Initialize-WinDependExternalMermaid -CheckOnly
        } | Out-Null

        Invoke-Step -Name 'GitHub CLI' -Action {
            Initialize-WinDependExternalGitHubCli -CheckOnly
        } | Out-Null

        Update-WinDependExternalFailureState
        return $state
    }

    # Normal initialization.
    Invoke-Step -Name 'Tectonic' -Action {
        Initialize-WinDependExternalTectonic
    } | Out-Null

    Invoke-Step -Name 'Ghostscript' -Action {
        Initialize-WinDependExternalGhostscript
    } | Out-Null

    Invoke-Step -Name 'ImageMagick' -Action {
        Initialize-WinDependExternalImageMagick
    } | Out-Null

    Invoke-Step -Name 'Mermaid CLI' -Action {
        Initialize-WinDependExternalMermaid
    } | Out-Null

    Invoke-Step -Name 'GitHub CLI' -Action {
        Initialize-WinDependExternalGitHubCli
    } | Out-Null

    if (-not $SkipPath) {
        Invoke-Step -Name 'External tool PATH configuration' -Action {
            Initialize-WinDependExternalPath
        } | Out-Null
    }

    Update-WinDependExternalFailureState

    return $state
}

