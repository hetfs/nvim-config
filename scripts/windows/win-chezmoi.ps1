# Install and configure chezmoi on native Windows and/or WSL2 Ubuntu.
#
# Standalone script.
# Does not depend on win-core.ps1 or win-depend.ps1.
#
# Usage:
#   .\win-chezmoi.ps1
#   .\win-chezmoi.ps1 -Target Both
#   .\win-chezmoi.ps1 -Target Windows
#   .\win-chezmoi.ps1 -Target WSL2
#   .\win-chezmoi.ps1 -Distribution Ubuntu
#   .\win-chezmoi.ps1 -CheckOnly
#   .\win-chezmoi.ps1 -Target Windows -CheckOnly
#   .\win-chezmoi.ps1 -Target WSL2 -CheckOnly
#
# Native Windows:
#   - chezmoi installed through WinGet.
#   - Package: twpayne.chezmoi
#
# WSL2:
#   - chezmoi installed using the official upstream installer.
#   - Installation directory: ~/.local/bin
#   - PATH configured in ~/.profile and ~/.bashrc
#
# Requirements:
#   - Windows 10/11
#   - WinGet for native Windows installation
#   - WSL2 for WSL2 installation
#   - An initialized Ubuntu distribution
#   - Internet connectivity

[CmdletBinding()]
param(
    [ValidateSet('Both', 'Windows', 'WSL2')]
    [string]$Target = 'Both',

    [string]$Distribution = 'Ubuntu',

    [switch]$CheckOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

$WingetPackageId = 'twpayne.chezmoi'
$WslInstallDir = '$HOME/.local/bin'

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------

function Write-Status {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('INFO', 'OK', 'WARN', 'ERROR')]
        [string]$Level,

        [Parameter(Mandatory)]
        [string]$Message
    )

    $Color = switch ($Level) {
        'INFO'  { 'Cyan' }
        'OK'    { 'Green' }
        'WARN'  { 'Yellow' }
        'ERROR' { 'Red' }
    }

    Write-Host "[$Level] $Message" -ForegroundColor $Color
}

function Write-Section {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Title
    )

    Write-Host ''
    Write-Host "=== $Title ===" -ForegroundColor White
}

# ---------------------------------------------------------------------------
# Native Windows: executable discovery
# ---------------------------------------------------------------------------

function Update-ProcessPath {
    [CmdletBinding()]
    param()

    $MachinePath = [Environment]::GetEnvironmentVariable(
        'Path',
        [EnvironmentVariableTarget]::Machine
    )

    $UserPath = [Environment]::GetEnvironmentVariable(
        'Path',
        [EnvironmentVariableTarget]::User
    )

    $env:Path = @(
        $MachinePath
        $UserPath
    ) -join ';'
}

function Get-WindowsExecutable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    Update-ProcessPath

    $Command = Get-Command $Name `
        -CommandType Application `
        -ErrorAction SilentlyContinue

    if (-not $Command) {
        return $null
    }

    return $Command.Source
}

function Get-WingetExecutable {
    [CmdletBinding()]
    param()

    $Winget = Get-WindowsExecutable -Name 'winget.exe'

    if (-not $Winget) {
        throw @'
WinGet is unavailable.

Install or update Microsoft App Installer from the Microsoft Store,
then open a new PowerShell session and retry.
'@
    }

    return $Winget
}

# ---------------------------------------------------------------------------
# Native Windows: installation verification
# ---------------------------------------------------------------------------

function Test-WindowsChezmoiInstallation {
    [CmdletBinding()]
    param()

    $Executable = Get-WindowsExecutable -Name 'chezmoi.exe'

    if (-not $Executable) {
        Write-Status -Level WARN -Message 'Native Windows chezmoi is not installed.'
        return $false
    }

    Write-Status -Level INFO -Message "Executable: $Executable"

    & $Executable --version

    if ($LASTEXITCODE -ne 0) {
        throw 'Native Windows chezmoi version verification failed.'
    }

    Write-Status -Level OK -Message 'Native Windows chezmoi is available.'

    return $true
}

# ---------------------------------------------------------------------------
# Native Windows: installation
# ---------------------------------------------------------------------------

function Install-WindowsChezmoi {
    [CmdletBinding()]
    param()

    Write-Status -Level INFO -Message 'Checking native Windows chezmoi...'

    if (Test-WindowsChezmoiInstallation) {
        Write-Status -Level OK -Message 'Native Windows chezmoi is already installed.'
        return
    }

    $Winget = Get-WingetExecutable

    Write-Status -Level INFO -Message "Installing $WingetPackageId through WinGet..."

    & $Winget install `
        --id $WingetPackageId `
        --exact `
        --silent `
        --accept-package-agreements `
        --accept-source-agreements `
        --disable-interactivity

    if ($LASTEXITCODE -ne 0) {
        throw "WinGet installation failed with exit code $LASTEXITCODE."
    }

    Update-ProcessPath

    if (-not (Test-WindowsChezmoiInstallation)) {
        throw @'
WinGet reported successful installation, but chezmoi.exe
could not be found in the current PATH.

Open a new PowerShell session and run this script again.
'@
    }

    Write-Status -Level OK -Message 'Native Windows chezmoi installation completed.'
}

# ---------------------------------------------------------------------------
# WSL: executable discovery
# ---------------------------------------------------------------------------

function Get-WslExecutable {
    [CmdletBinding()]
    param()

    $Command = Get-Command 'wsl.exe' -ErrorAction SilentlyContinue

    if (-not $Command) {
        throw 'WSL is not installed or wsl.exe is unavailable on PATH.'
    }

    return $Command.Source
}

# ---------------------------------------------------------------------------
# WSL: distribution discovery
# ---------------------------------------------------------------------------

function Get-WslDistributions {
    [CmdletBinding()]
    param()

    $Wsl = Get-WslExecutable

    $Output = & $Wsl --list --verbose 2>&1

    if ($LASTEXITCODE -ne 0) {
        throw "Unable to list WSL distributions: $Output"
    }

    $Text = ($Output -join "`n") -replace "`0", ''

    $Results = @()

    foreach ($Line in ($Text -split "`r?`n")) {
        if ($Line -match '^\s*\*?\s*(?<Name>.+?)\s+(?<State>Running|Stopped)\s+(?<Version>[12])\s*$') {
            $Results += [PSCustomObject]@{
                Name    = $Matches.Name.Trim()
                State   = $Matches.State
                Version = [int]$Matches.Version
            }
        }
    }

    return $Results
}

function Get-TargetWslDistribution {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    $Distributions = @(Get-WslDistributions)

    $DistributionInfo = $Distributions |
        Where-Object { $_.Name -ieq $Name } |
        Select-Object -First 1

    if (-not $DistributionInfo) {
        throw @"
WSL distribution '$Name' was not found.

Install Ubuntu with:

    wsl.exe --install -d Ubuntu

Complete the initial Ubuntu setup and run this script again.
"@
    }

    if ($DistributionInfo.Version -ne 2) {
        throw @"
Distribution '$Name' is running WSL $($DistributionInfo.Version).

chezmoi provisioning requires WSL2.

Convert the distribution using:

    wsl.exe --set-version "$Name" 2
"@
    }

    return $DistributionInfo
}

# ---------------------------------------------------------------------------
# WSL: command execution
# ---------------------------------------------------------------------------

function Invoke-WslScript {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Distribution,

        [Parameter(Mandatory)]
        [string]$Script
    )

    $Wsl = Get-WslExecutable

    & $Wsl `
        --distribution $Distribution `
        --exec bash -lc $Script

    if ($LASTEXITCODE -ne 0) {
        throw "WSL command failed with exit code $LASTEXITCODE."
    }
}

# ---------------------------------------------------------------------------
# WSL: installation verification
# ---------------------------------------------------------------------------

function Test-WslChezmoiInstallation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Distribution
    )

    $CheckScript = @'
set -u

export PATH="$HOME/.local/bin:$PATH"

if command -v chezmoi >/dev/null 2>&1; then
    echo "[OK] chezmoi: $(command -v chezmoi)"
    chezmoi --version
else
    echo "[MISSING] chezmoi"
    exit 1
fi
'@

    Invoke-WslScript `
        -Distribution $Distribution `
        -Script $CheckScript
}

# ---------------------------------------------------------------------------
# WSL: installation
# ---------------------------------------------------------------------------

function Install-WslChezmoi {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Distribution
    )

    $InstallScript = @'
set -euo pipefail

INSTALL_DIR="$HOME/.local/bin"

# ---------------------------------------------------------------------------
# Check existing installation
# ---------------------------------------------------------------------------

if command -v chezmoi >/dev/null 2>&1; then
    echo "[OK] chezmoi is already installed: $(command -v chezmoi)"
else
    # -----------------------------------------------------------------------
    # Install prerequisites
    # -----------------------------------------------------------------------

    echo "[INFO] Installing prerequisites..."

    sudo apt-get update

    sudo apt-get install -y \
        curl \
        ca-certificates

    # -----------------------------------------------------------------------
    # Install official chezmoi binary
    # -----------------------------------------------------------------------

    echo "[INFO] Creating installation directory..."

    mkdir -p "$INSTALL_DIR"

    echo "[INFO] Installing chezmoi..."

    sh -c "$(curl -fsLS https://get.chezmoi.io)" -- -b "$INSTALL_DIR"
fi

# ---------------------------------------------------------------------------
# Configure PATH
# ---------------------------------------------------------------------------

PATH_LINE='export PATH="$HOME/.local/bin:$PATH"'

for PROFILE in "$HOME/.profile" "$HOME/.bashrc"; do
    touch "$PROFILE"

    if ! grep -Fqx -- "$PATH_LINE" "$PROFILE"; then
        {
            echo
            echo "# chezmoi installation"
            echo "$PATH_LINE"
        } >> "$PROFILE"
    fi
done

export PATH="$INSTALL_DIR:$PATH"

# ---------------------------------------------------------------------------
# Verify installation
# ---------------------------------------------------------------------------

echo "[INFO] Verifying installation..."

command -v chezmoi
chezmoi --version

echo "[OK] WSL2 chezmoi installation completed."
'@

    Invoke-WslScript `
        -Distribution $Distribution `
        -Script $InstallScript
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

try {
    Write-Section -Title 'CHEZMOI PROVISIONER'

    Write-Status -Level INFO -Message "Target: $Target"

    if ($CheckOnly) {
        Write-Status -Level INFO -Message 'Check-only mode enabled. No installation changes will be made.'
    }

    # -----------------------------------------------------------------------
    # Native Windows
    # -----------------------------------------------------------------------

    if ($Target -in @('Both', 'Windows')) {
        Write-Section -Title 'NATIVE WINDOWS CHEZMOI'

        if ($CheckOnly) {
            if (-not (Test-WindowsChezmoiInstallation)) {
                throw 'Native Windows chezmoi check failed.'
            }
        }
        else {
            Install-WindowsChezmoi
        }

        Write-Status -Level OK -Message 'Native Windows stage completed.'
    }

    # -----------------------------------------------------------------------
    # WSL2
    # -----------------------------------------------------------------------

    if ($Target -in @('Both', 'WSL2')) {
        Write-Section -Title 'WSL2 CHEZMOI'

        Write-Status -Level INFO -Message 'Checking WSL availability...'

        $Wsl = Get-WslExecutable

        Write-Status -Level OK -Message "WSL executable: $Wsl"

        Write-Status -Level INFO -Message "Checking distribution: $Distribution"

        $DistributionInfo = Get-TargetWslDistribution -Name $Distribution

        Write-Status -Level OK -Message (
            "WSL2 distribution available: {0} ({1})" -f
            $DistributionInfo.Name,
            $DistributionInfo.State
        )

        if ($CheckOnly) {
            Test-WslChezmoiInstallation -Distribution $Distribution
        }
        else {
            Install-WslChezmoi -Distribution $Distribution

            Write-Section -Title 'WSL2 INSTALLATION VERIFICATION'

            Test-WslChezmoiInstallation -Distribution $Distribution
        }

        Write-Status -Level OK -Message 'WSL2 stage completed.'
    }

    # -----------------------------------------------------------------------
    # Completion
    # -----------------------------------------------------------------------

    Write-Host ''
    Write-Status -Level OK -Message 'chezmoi provisioning completed successfully.'

    exit 0
}
catch {
    Write-Host ''
    Write-Status -Level ERROR -Message $_.Exception.Message

    exit 1
}

