# Install and configure Ansible inside WSL2 Ubuntu.
#
# Standalone script.
# Does not depend on win-core.ps1 or win-depend.ps1.
#
# Usage:
#   .\win-ansible.ps1
#   .\win-ansible.ps1 -Distribution Ubuntu
#   .\win-ansible.ps1 -CheckOnly
#   .\win-ansible.ps1 -Distribution Ubuntu-24.04 -CheckOnly
#
# Installed inside WSL2:
#   - Python 3
#   - pipx
#   - Ansible
#   - ansible-lint
#   - yamllint
#   - Git
#   - OpenSSH client

[CmdletBinding()]
param(
    [string]$Distribution = 'Ubuntu',

    [switch]$CheckOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

$ScriptName = 'Ansible WSL2 Provisioner'

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
# WSL validation
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

function Get-WslDistributions {
    [CmdletBinding()]
    param()

    $Wsl = Get-WslExecutable

    $Output = & $Wsl --list --quiet 2>&1

    if ($LASTEXITCODE -ne 0) {
        throw "Unable to list WSL distributions: $Output"
    }

    # WSL can return UTF-16 output with null characters.
    $Text = ($Output -join "`n") -replace "`0", ''

    return @(
        $Text -split "`r?`n" |
            ForEach-Object { $_.Trim() } |
            Where-Object { $_ }
    )
}

function Test-WslDistribution {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    $Distributions = @(Get-WslDistributions)

    return [bool](
        $Distributions |
            Where-Object { $_ -ieq $Name } |
            Select-Object -First 1
    )
}

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
        throw "WSL installation failed with exit code $LASTEXITCODE."
    }
}

# ---------------------------------------------------------------------------
# Ansible verification
# ---------------------------------------------------------------------------

function Test-AnsibleInstallation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Distribution
    )

    $CheckScript = @'
set -u

export PATH="$HOME/.local/bin:$PATH"

check_command() {
    local name="$1"

    if command -v "$name" >/dev/null 2>&1; then
        printf '[OK] %s: ' "$name"
        "$name" --version 2>&1 | head -n 1 || true
    else
        printf '[MISSING] %s\n' "$name"
    fi
}

echo "Ansible environment:"

check_command python3
check_command pipx
check_command ansible
check_command ansible-playbook
check_command ansible-lint
check_command yamllint
check_command git
check_command ssh
'@

    Invoke-WslScript `
        -Distribution $Distribution `
        -Script $CheckScript
}

# ---------------------------------------------------------------------------
# Installation
# ---------------------------------------------------------------------------

function Install-Ansible {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Distribution
    )

    $InstallScript = @'
set -euo pipefail

export PATH="$HOME/.local/bin:$PATH"

echo "[INFO] Updating Ubuntu package indexes..."

sudo apt-get update

echo "[INFO] Installing system dependencies..."

sudo apt-get install -y \
    python3 \
    python3-venv \
    pipx \
    git \
    openssh-client \
    yamllint

echo "[INFO] Configuring pipx..."

pipx ensurepath

echo "[INFO] Installing Ansible..."

if command -v ansible >/dev/null 2>&1; then
    echo "[OK] Ansible is already installed."
else
    pipx install --include-deps ansible
fi

echo "[INFO] Installing ansible-lint..."

if command -v ansible-lint >/dev/null 2>&1; then
    echo "[OK] ansible-lint is already installed."
else
    pipx install ansible-lint
fi

echo "[OK] Ansible installation completed."
'@

    Invoke-WslScript `
        -Distribution $Distribution `
        -Script $InstallScript
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

try {
    Write-Section -Title $ScriptName

    Write-Status -Level INFO -Message 'Checking WSL availability...'

    $Wsl = Get-WslExecutable

    Write-Status -Level OK -Message "WSL executable: $Wsl"

    Write-Status -Level INFO -Message "Checking distribution: $Distribution"

    if (-not (Test-WslDistribution -Name $Distribution)) {
        throw @"
WSL distribution '$Distribution' was not found.

Install Ubuntu with:

    wsl.exe --install -d Ubuntu

Complete the initial Ubuntu setup and run this script again.
"@
    }

    Write-Status -Level OK -Message "Distribution available: $Distribution"

    if ($CheckOnly) {
        Write-Section -Title 'ANSIBLE INSTALLATION CHECK'

        Test-AnsibleInstallation -Distribution $Distribution

        Write-Status -Level OK -Message 'Check completed.'
        exit 0
    }

    Write-Section -Title 'ANSIBLE INSTALLATION'

    Install-Ansible -Distribution $Distribution

    Write-Section -Title 'INSTALLATION VERIFICATION'

    Test-AnsibleInstallation -Distribution $Distribution

    Write-Host ''
    Write-Status -Level OK -Message 'Ansible provisioning completed successfully.'
    exit 0
}
catch {
    Write-Host ''
    Write-Status -Level ERROR -Message $_.Exception.Message
    exit 1
}

