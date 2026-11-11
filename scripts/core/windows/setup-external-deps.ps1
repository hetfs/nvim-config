

[CmdletBinding()]
param(
    [switch]$CheckOnly,
    [switch]$ConfigurePathOnly,
    [switch]$SkipPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

$TectonicInstallDir = Join-Path $env:LOCALAPPDATA 'Programs\Tectonic'
$GhostscriptVersion = '10.08.0'
$GhostscriptInstallDir = "C:\Program Files\gs\gs$GhostscriptVersion"
$GhostscriptInstaller = "gs10080w64.exe"

$GhostscriptDownloadUrl = (
    "https://github.com/ArtifexSoftware/ghostpdl-downloads/" +
    "releases/download/gs10080/$GhostscriptInstaller"
)

$GhostscriptSha256 = (
    '52a91b8bf09298788d7a57b920612702' +
    '6c23eacd75405f0a131e26dc381dce50'
)

$ImageMagickPackageId = 'ImageMagick.Q16-HDRI'
$MermaidPackage = '@mermaid-js/mermaid-cli'

$ShimDir = Join-Path $HOME '.local\bin'
$ShimPath = Join-Path $ShimDir 'gs.cmd'

$script:Results = [System.Collections.Generic.List[object]]::new()

# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------

function Write-Section {
    param([string]$Message)

    Write-Host ''
    Write-Host $Message -ForegroundColor Cyan
    Write-Host ('-' * $Message.Length) -ForegroundColor DarkGray
}

function Add-Result {
    param(
        [string]$Name,
        [string]$Status,
        [string]$Message
    )

    $script:Results.Add([PSCustomObject]@{
        Name    = $Name
        Status  = $Status
        Message = $Message
    })

    $color = switch ($Status) {
        'OK'      { 'Green' }
        'FAIL'    { 'Red' }
        'SKIPPED' { 'Yellow' }
        default   { 'Gray' }
    }

    Write-Host "[$Status] $Name - $Message" -ForegroundColor $color
}

function Confirm-Action {
    param([string]$Message)

    $answer = Read-Host "$Message [y/N]"
    return $answer -match '^(y|yes)$'
}

# ---------------------------------------------------------------------------
# PATH management
# ---------------------------------------------------------------------------

function Add-UserPath {
    param(
        [Parameter(Mandatory)]
        [string]$Directory
    )

    if (-not (Test-Path -LiteralPath $Directory -PathType Container)) {
        throw "PATH directory does not exist: $Directory"
    }

    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')

    $entries = @(
        $userPath -split ';' |
            Where-Object { $_.Trim() }
    )

    $alreadyPresent = $entries | Where-Object {
        [string]::Equals(
            $_.TrimEnd('\'),
            $Directory.TrimEnd('\'),
            [StringComparison]::OrdinalIgnoreCase
        )
    }

    if (-not $alreadyPresent) {
        $entries += $Directory

        [Environment]::SetEnvironmentVariable(
            'Path',
            ($entries -join ';'),
            'User'
        )
    }

    $processEntries = @(
        $env:Path -split ';' |
            Where-Object { $_.Trim() }
    )

    $processPresent = $processEntries | Where-Object {
        [string]::Equals(
            $_.TrimEnd('\'),
            $Directory.TrimEnd('\'),
            [StringComparison]::OrdinalIgnoreCase
        )
    }

    if (-not $processPresent) {
        $env:Path = "$Directory;$env:Path"
    }
}

# ---------------------------------------------------------------------------
# Command discovery and verification
# ---------------------------------------------------------------------------

function Get-Application {
    param([string]$Name)

    return Get-Command -Name $Name -CommandType Application `
        -ErrorAction SilentlyContinue |
        Select-Object -First 1
}

function Invoke-VersionCheck {
    param(
        [string]$Name,
        [string[]]$Arguments
    )

    $command = Get-Application -Name $Name

    if (-not $command) {
        Add-Result $Name 'FAIL' 'Executable not found.'
        return $false
    }

    try {
        $output = @(& $command.Source @Arguments 2>&1)
        $exitCode = $LASTEXITCODE

        if ($exitCode -ne 0) {
            Add-Result $Name 'FAIL' "Version command exited with code $exitCode."
            return $false
        }

        $message = ($output |
            ForEach-Object { "$_".Trim() } |
            Where-Object { $_ }) -join ' '

        # ImageMagick prints several lines. Keep the summary concise.
        if ($Name -eq 'magick' -and $output.Count -gt 0) {
            $message = "$($output[0])".Trim()
        }

        Add-Result $Name 'OK' $message
        return $true
    }
    catch {
        Add-Result $Name 'FAIL' $_.Exception.Message
        return $false
    }
}

function Invoke-InstallerCommand {
    param(
        [string]$Name,
        [string[]]$Arguments
    )

    $command = Get-Application -Name $Name

    if (-not $command) {
        throw "Required installer command not found: $Name"
    }

    & $command.Source @Arguments

    if ($LASTEXITCODE -ne 0) {
        throw "$Name exited with code $LASTEXITCODE."
    }
}

# ---------------------------------------------------------------------------
# Tectonic
# ---------------------------------------------------------------------------

function Install-Tectonic {
    if (Get-Application 'tectonic') {
        Add-Result 'tectonic' 'OK' 'Already installed. No changes made.'
        return
    }

    Write-Host ''
    Write-Host 'Tectonic uses its official Windows bootstrap script.' `
        -ForegroundColor Yellow

    if (-not (Confirm-Action 'Download and execute the official Tectonic bootstrap script?')) {
        Add-Result 'tectonic' 'SKIPPED' 'Installation declined.'
        return
    }

    $tempDir = Join-Path $env:TEMP (
        'tectonic-install-' + [guid]::NewGuid().ToString('N')
    )

    New-Item -ItemType Directory -Path $tempDir -Force |
        Out-Null

    try {
        $bootstrapPath = Join-Path $tempDir 'install.ps1'

        Invoke-WebRequest `
            -Uri 'https://drop-ps1.fullyjustified.net' `
            -OutFile $bootstrapPath

        # The downloaded script is executed only after explicit consent.
        $bootstrapContent = Get-Content -LiteralPath $bootstrapPath -Raw

        Push-Location $tempDir

        try {
            Invoke-Expression $bootstrapContent
        }
        finally {
            Pop-Location
        }

        $downloadedExecutable = Join-Path $tempDir 'tectonic.exe'

        if (-not (Test-Path -LiteralPath $downloadedExecutable)) {
            throw 'Tectonic bootstrap completed without producing tectonic.exe.'
        }

        New-Item -ItemType Directory -Path $TectonicInstallDir -Force |
            Out-Null

        $destination = Join-Path $TectonicInstallDir 'tectonic.exe'

        Move-Item -LiteralPath $downloadedExecutable `
            -Destination $destination -Force

        Add-Result 'tectonic' 'OK' 'Installed successfully.'
    }
    finally {
        Remove-Item -LiteralPath $tempDir -Recurse -Force `
            -ErrorAction SilentlyContinue
    }
}

# ---------------------------------------------------------------------------
# Mermaid CLI and Puppeteer
# ---------------------------------------------------------------------------

function Install-Mermaid {
    if (Get-Application 'mmdc') {
        Add-Result 'mmdc' 'OK' 'Already installed. No changes made.'
        return
    }

    if (-not (Get-Application 'npm')) {
        throw 'npm is required to install Mermaid CLI.'
    }

    Invoke-InstallerCommand -Name 'npm' -Arguments @(
        'install',
        '--global',
        $MermaidPackage,
        '--allow-scripts=puppeteer'
    )

    Add-Result 'mmdc' 'OK' 'Mermaid CLI installation completed.'
}

# ---------------------------------------------------------------------------
# ImageMagick
# ---------------------------------------------------------------------------

function Install-ImageMagick {
    if (Get-Application 'magick') {
        Add-Result 'magick' 'OK' 'Already installed. No changes made.'
        return
    }

    if (-not (Get-Application 'winget')) {
        throw 'WinGet is required to install ImageMagick.'
    }

    Invoke-InstallerCommand -Name 'winget' -Arguments @(
        'install',
        '--exact',
        '--id',
        $ImageMagickPackageId,
        '--accept-package-agreements',
        '--accept-source-agreements',
        '--silent'
    )

    $package = Get-AppxPackage -Name $ImageMagickPackageId

    if (-not $package) {
        throw 'ImageMagick installation was not detected after WinGet completed.'
    }

    Add-UserPath -Directory $package.InstallLocation

    Add-Result 'magick' 'OK' 'ImageMagick installed and PATH configured.'
}

# ---------------------------------------------------------------------------
# Ghostscript
# ---------------------------------------------------------------------------

function Find-Ghostscript {
    $command = Get-Application 'gswin64c'

    if ($command) {
        return $command.Source
    }

    $expectedPath = Join-Path $GhostscriptInstallDir 'bin\gswin64c.exe'

    if (Test-Path -LiteralPath $expectedPath) {
        return $expectedPath
    }

    return $null
}

function Install-Ghostscript {
    $existing = Find-Ghostscript

    if (-not $existing) {
        $tempInstaller = Join-Path $env:TEMP $GhostscriptInstaller

        try {
            Write-Host 'Downloading official Ghostscript installer...'

            Invoke-WebRequest `
                -Uri $GhostscriptDownloadUrl `
                -OutFile $tempInstaller

            $actualHash = (
                Get-FileHash -LiteralPath $tempInstaller -Algorithm SHA256
            ).Hash.ToLowerInvariant()

            if ($actualHash -ne $GhostscriptSha256) {
                throw 'Ghostscript installer SHA-256 verification failed.'
            }

            Add-Result 'Ghostscript download' 'OK' 'SHA-256 verified.'

            if (-not (Confirm-Action 'Run the verified Ghostscript installer?')) {
                Add-Result 'gs' 'SKIPPED' 'Installation declined.'
                return
            }

            # The official installer may request elevation and user interaction.
            $process = Start-Process `
                -FilePath $tempInstaller `
                -Verb RunAs `
                -Wait `
                -PassThru

            if ($process.ExitCode -ne 0) {
                throw "Ghostscript installer exited with code $($process.ExitCode)."
            }
        }
        finally {
            Remove-Item -LiteralPath $tempInstaller -Force `
                -ErrorAction SilentlyContinue
        }
    }
    else {
        Add-Result 'gswin64c' 'OK' 'Ghostscript already installed.'
    }

    $ghostscriptExe = Find-Ghostscript

    if (-not $ghostscriptExe) {
        throw 'Ghostscript executable was not found after installation.'
    }

    $ghostscriptBin = Split-Path -Parent $ghostscriptExe

    if (-not $SkipPath) {
        Add-UserPath -Directory $ghostscriptBin
        Add-UserPath -Directory $ShimDir
    }

    New-Item -ItemType Directory -Path $ShimDir -Force |
        Out-Null

    $shimContent = @"
@echo off
"$ghostscriptExe" %*
exit /b %ERRORLEVEL%
"@

    Set-Content -LiteralPath $ShimPath -Value $shimContent -Encoding Ascii

    Add-Result 'gs' 'OK' 'Ghostscript installed or detected; compatibility shim configured.'
}

# ---------------------------------------------------------------------------
# PATH configuration
# ---------------------------------------------------------------------------

function Configure-ExternalPaths {
    if ($SkipPath) {
        Write-Host 'PATH configuration skipped.' -ForegroundColor Yellow
        return
    }

    if (Test-Path -LiteralPath $TectonicInstallDir) {
        Add-UserPath -Directory $TectonicInstallDir
    }

    $imageMagick = Get-AppxPackage -Name $ImageMagickPackageId

    if ($imageMagick) {
        Add-UserPath -Directory $imageMagick.InstallLocation
    }

    $npm = Get-Application 'npm'

    if ($npm) {
        $npmPrefix = (& $npm.Source prefix --global 2>$null)

        if ($LASTEXITCODE -eq 0 -and $npmPrefix) {
            $npmBin = Join-Path "$npmPrefix" ''

            if (Test-Path -LiteralPath $npmBin) {
                Add-UserPath -Directory $npmBin
            }
        }
    }

    if (Test-Path -LiteralPath $ShimDir) {
        Add-UserPath -Directory $ShimDir
    }

    $ghostscriptExe = Find-Ghostscript

    if ($ghostscriptExe) {
        Add-UserPath -Directory (Split-Path -Parent $ghostscriptExe)
    }

    Add-Result 'PATH' 'OK' 'Available installation directories configured.'
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

Write-Section 'Windows External Dependency Setup'

Write-Host 'Installation mode:'
Write-Host "  Check only:          $CheckOnly"
Write-Host "  Configure PATH only: $ConfigurePathOnly"
Write-Host "  Skip PATH:           $SkipPath"

if (-not $CheckOnly -and -not $ConfigurePathOnly) {
    Write-Section 'Installing Missing Dependencies'

    $installers = @(
        @{ Name = 'Tectonic'; Action = { Install-Tectonic } }
        @{ Name = 'Mermaid CLI'; Action = { Install-Mermaid } }
        @{ Name = 'ImageMagick'; Action = { Install-ImageMagick } }
        @{ Name = 'Ghostscript'; Action = { Install-Ghostscript } }
    )

    foreach ($installer in $installers) {
        try {
            & $installer.Action
        }
        catch {
            Add-Result $installer.Name 'FAIL' $_.Exception.Message
        }
    }
}

if (-not $SkipPath) {
    try {
        Configure-ExternalPaths
    }
    catch {
        Add-Result 'PATH' 'FAIL' $_.Exception.Message
    }
}

Write-Section 'Dependency Verification'

# Refresh command discovery after PATH changes.
$env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') +
    ';' +
    [Environment]::GetEnvironmentVariable('Path', 'User')

$checks = @(
    @{ Name = 'tectonic'; Arguments = @('--version') }
    @{ Name = 'mmdc';     Arguments = @('--version') }
    @{ Name = 'magick';   Arguments = @('-version') }
    @{ Name = 'gs';       Arguments = @('--version') }
)

foreach ($check in $checks) {
    Invoke-VersionCheck `
        -Name $check.Name `
        -Arguments $check.Arguments
}

Write-Section 'Summary'

$passed = @($script:Results | Where-Object Status -eq 'OK').Count
$failed = @($script:Results | Where-Object Status -eq 'FAIL').Count
$skipped = @($script:Results | Where-Object Status -eq 'SKIPPED').Count

Write-Host "Passed:  $passed" -ForegroundColor Green
Write-Host "Failed:  $failed" -ForegroundColor $(if ($failed) { 'Red' } else { 'Green' })
Write-Host "Skipped: $skipped" -ForegroundColor Yellow

if ($failed -gt 0) {
    Write-Host ''
    Write-Host 'Dependency setup completed with errors.' -ForegroundColor Red
    exit 1
}

Write-Host ''
Write-Host 'Dependency setup completed.' -ForegroundColor Green
exit 0
