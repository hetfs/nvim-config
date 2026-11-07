# Install external dependencies for the Neovim PowerShell language pack.
#
# Usage:
#   .\scripts\install\core\powershell.ps1
#   .\scripts\install\core\powershell.ps1 -Check
#   .\scripts\install\core\powershell.ps1 -Update
#
# Required external tools:
#   - PowerShell 7+
#   - PowerShell Editor Services (PSES)
#   - PSScriptAnalyzer
#
# Installation policy:
#   - Does not install or update PowerShell itself.
#   - Installs PSES into the current user's LocalAppData directory.
#   - Installs PSScriptAnalyzer for the current user.
#   - Does not change PowerShell execution policies.
#   - Does not modify global module paths.
#   - Does not run automatically during Neovim startup.

[CmdletBinding()]
param(
    [switch]$Check,
    [switch]$Update
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

$PSESRepository = "PowerShell/PowerShellEditorServices"
$PSESBundleRoot = Join-Path $env:LOCALAPPDATA "Programs\PSES\PowerShellEditorServices"
$PSESStartupScript = Join-Path $PSESBundleRoot "PowerShellEditorServices\Start-EditorServices.ps1"

$RequiredPowerShellMajorVersion = 7
$RequiredModule = "PSScriptAnalyzer"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

function Write-Status {
    param([string]$Message)

    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)

    Write-Host "[PASS] $Message" -ForegroundColor Green
}

function Write-WarningMessage {
    param([string]$Message)

    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-Failure {
    param([string]$Message)

    Write-Host "[FAIL] $Message" -ForegroundColor Red
}

function Test-PowerShellVersion {
    $version = $PSVersionTable.PSVersion

    if ($version.Major -lt $RequiredPowerShellMajorVersion) {
        throw "PowerShell 7 or later is required. Current version: $version"
    }

    Write-Success "PowerShell $version"
}

function Get-PSESInstallation {
    if (-not (Test-Path -LiteralPath $PSESStartupScript -PathType Leaf)) {
        return $null
    }

    return Get-Item -LiteralPath $PSESStartupScript
}

function Get-PSScriptAnalyzerInstallation {
    return Get-Module -ListAvailable -Name $RequiredModule |
        Sort-Object Version -Descending |
        Select-Object -First 1
}

function Test-Dependencies {
    $failed = $false

    Write-Host ""
    Write-Status "Checking PowerShell language dependencies..."

    try {
        Test-PowerShellVersion
    }
    catch {
        Write-Failure $_.Exception.Message
        $failed = $true
    }

    if (Get-PSESInstallation) {
        Write-Success "PowerShell Editor Services is installed."
    }
    else {
        Write-Failure "PowerShell Editor Services is missing: $PSESBundleRoot"
        $failed = $true
    }

    $module = Get-PSScriptAnalyzerInstallation

    if ($module) {
        Write-Success "PSScriptAnalyzer $($module.Version) is installed."
    }
    else {
        Write-Failure "PSScriptAnalyzer is not installed."
        $failed = $true
    }

    if ($failed) {
        throw "One or more PowerShell dependencies are missing or invalid."
    }

    Write-Host ""
    Write-Success "All PowerShell dependencies are available."
}

# ---------------------------------------------------------------------------
# PowerShell Editor Services
# ---------------------------------------------------------------------------

function Install-PSES {
    param(
        [switch]$Force
    )

    if (-not $Force -and (Get-PSESInstallation)) {
        Write-Success "PowerShell Editor Services is already installed."
        return
    }

    Write-Status "Resolving the latest stable PSES release..."

    $headers = @{
        Accept = "application/vnd.github+json"
        "X-GitHub-Api-Version" = "2022-11-28"
    }

    $releaseUri = "https://api.github.com/repos/$PSESRepository/releases/latest"

    $release = Invoke-RestMethod `
        -Uri $releaseUri `
        -Headers $headers

    if (-not $release.assets) {
        throw "The PSES release contains no downloadable assets."
    }

    $asset = $release.assets |
        Where-Object { $_.name -eq "PowerShellEditorServices.zip" } |
        Select-Object -First 1

    if (-not $asset) {
        throw "Could not find PowerShellEditorServices.zip in the latest PSES release."
    }

    Write-Status "Selected PSES release: $($release.tag_name)"

    $temporaryRoot = Join-Path ([System.IO.Path]::GetTempPath()) (
        "nvim-powershell-" + [guid]::NewGuid().ToString("N")
    )

    $archivePath = Join-Path $temporaryRoot "PowerShellEditorServices.zip"
    $stagingPath = Join-Path $temporaryRoot "extracted"
    $backupPath = "$PSESBundleRoot.backup"

    New-Item -ItemType Directory -Path $temporaryRoot -Force | Out-Null
    New-Item -ItemType Directory -Path $stagingPath -Force | Out-Null

    try {
        Write-Status "Downloading PSES..."

        Invoke-WebRequest `
            -Uri $asset.browser_download_url `
            -OutFile $archivePath

        Write-Status "Extracting PSES..."

        Expand-Archive `
            -LiteralPath $archivePath `
            -DestinationPath $stagingPath `
            -Force

        $stagedStartupScript = Join-Path `
            $stagingPath `
            "PowerShellEditorServices\Start-EditorServices.ps1"

        if (-not (Test-Path -LiteralPath $stagedStartupScript -PathType Leaf)) {
            throw "The extracted archive does not contain the expected PSES startup script."
        }

        $parentDirectory = Split-Path -Parent $PSESBundleRoot

        New-Item -ItemType Directory -Path $parentDirectory -Force | Out-Null

        if (Test-Path -LiteralPath $backupPath) {
            Remove-Item -LiteralPath $backupPath -Recurse -Force
        }

        if (Test-Path -LiteralPath $PSESBundleRoot) {
            Move-Item -LiteralPath $PSESBundleRoot -Destination $backupPath
        }

        try {
            Move-Item -LiteralPath $stagingPath -Destination $PSESBundleRoot

            if (-not (Test-Path -LiteralPath $PSESStartupScript -PathType Leaf)) {
                throw "PSES installation verification failed."
            }

            if (Test-Path -LiteralPath $backupPath) {
                Remove-Item -LiteralPath $backupPath -Recurse -Force
            }
        }
        catch {
            if (Test-Path -LiteralPath $PSESBundleRoot) {
                Remove-Item -LiteralPath $PSESBundleRoot -Recurse -Force
            }

            if (Test-Path -LiteralPath $backupPath) {
                Move-Item -LiteralPath $backupPath -Destination $PSESBundleRoot
            }

            throw
        }

        Write-Success "PSES $($release.tag_name) installed."
        Write-Status "Installation path: $PSESBundleRoot"
    }
    finally {
        if (Test-Path -LiteralPath $temporaryRoot) {
            Remove-Item -LiteralPath $temporaryRoot -Recurse -Force
        }
    }
}

# ---------------------------------------------------------------------------
# PSScriptAnalyzer
# ---------------------------------------------------------------------------

function Install-PSScriptAnalyzer {
    param(
        [switch]$Force
    )

    $installedModule = Get-PSScriptAnalyzerInstallation

    if (-not $Force -and $installedModule) {
        Write-Success "PSScriptAnalyzer $($installedModule.Version) is already installed."
        return
    }

    if (-not (Get-Command Install-Module -ErrorAction SilentlyContinue)) {
        throw "Install-Module is unavailable. Install PowerShellGet before continuing."
    }

    Write-Status "Installing PSScriptAnalyzer for the current user..."

    Install-Module `
        -Name $RequiredModule `
        -Repository PSGallery `
        -Scope CurrentUser `
        -Force `
        -AllowClobber

    $installedModule = Get-PSScriptAnalyzerInstallation

    if (-not $installedModule) {
        throw "PSScriptAnalyzer installation verification failed."
    }

    Write-Success "PSScriptAnalyzer $($installedModule.Version) installed."
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

try {
    Test-PowerShellVersion

    if ($Check) {
        Test-Dependencies
        exit 0
    }

    Write-Host ""
    Write-Status "Preparing PowerShell language dependencies..."

    Install-PSES -Force:$Update
    Install-PSScriptAnalyzer -Force:$Update

    Write-Host ""
    Test-Dependencies
}
catch {
    Write-Host ""
    Write-Failure $_.Exception.Message
    exit 1
}
