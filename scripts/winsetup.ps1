# Install nvim-config on Windows.
# Run from PowerShell 7 or Windows PowerShell.
# The repository is cloned and smoke-tested before the active configuration
# or existing backups are changed. The installed .git directory is retained.

[CmdletBinding()]
param(
    [string]$Repository = "https://github.com/hetfs/nvim-config.git",
    [string]$ConfigName = "nvim",
    [switch]$SkipRuntimeDataBackup
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root = $env:LOCALAPPDATA
if ([string]::IsNullOrWhiteSpace($root)) {
    throw "LOCALAPPDATA is not set. Cannot determine the installation directory."
}
if (-not (Test-Path -LiteralPath $root -PathType Container)) {
    throw "LOCALAPPDATA does not point to an existing directory: $root"
}
if ([string]::IsNullOrWhiteSpace($ConfigName) -or $ConfigName -match '[\\/:*?"<>|]') {
    throw "ConfigName must be a simple directory name, such as 'nvim'."
}

$config = Join-Path $root $ConfigName
$configBackup = "$config.bak"
$data = Join-Path $root "$ConfigName-data"
$dataBackup = "$data.bak"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss-fff"
$staging = Join-Path $root "$ConfigName-install-$timestamp"
$configRecovery = Join-Path $root "$ConfigName-recovery-$timestamp"
$oldConfigBackup = Join-Path $root "$ConfigName-old-backup-$timestamp"
$failedInstall = Join-Path $root "$ConfigName-failed-install-$timestamp"
$dataBackupTemp = Join-Path $root "$ConfigName-data-backup-$timestamp"
$dataBackupRecovery = Join-Path $root "$ConfigName-data-backup-recovery-$timestamp"

foreach ($commandName in @("git", "nvim", "rg")) {
    if (-not (Get-Command $commandName -ErrorAction SilentlyContinue)) {
        throw "Required command '$commandName' was not found. Install it and retry."
    }
}

foreach ($path in @($staging, $configRecovery, $oldConfigBackup, $failedInstall, $dataBackupTemp, $dataBackupRecovery)) {
    if (Test-Path -LiteralPath $path) {
        throw "Safety check: temporary path already exists: $path"
    }
}

Write-Host "Repository: $Repository"
Write-Host "Install target: $config"
Write-Host "Configuration backup to refresh when an installation exists: $configBackup"
if (-not $SkipRuntimeDataBackup) {
    Write-Host "Runtime-data backup to refresh: $dataBackup"
}

# Clone and validate before changing the active configuration or backups.
Write-Host "`n[1/4] Cloning repository..."
& git clone -- $Repository $staging
if ($LASTEXITCODE -ne 0) {
    throw "Git clone failed. The active configuration and backups were not changed."
}

Write-Host "`n[2/4] Validating cloned configuration..."
$initFile = Join-Path $staging "init.lua"
$smokeScript = Join-Path $staging "scripts\smoke.lua"
if (-not (Test-Path -LiteralPath $initFile -PathType Leaf)) {
    throw "The cloned repository is missing init.lua. Clone retained at: $staging"
}
if (-not (Test-Path -LiteralPath $smokeScript -PathType Leaf)) {
    throw "The cloned repository is missing scripts\smoke.lua. Clone retained at: $staging"
}

Push-Location $staging
try {
    & nvim --headless -u $initFile -c "luafile scripts/smoke.lua"
    if ($LASTEXITCODE -ne 0) {
        throw "Smoke test failed. The active configuration and backups were not changed. Clone retained at: $staging"
    }
} finally {
    Pop-Location
}

# Prepare a runtime-data backup copy before changing the active configuration.
# The live nvim-data directory is never moved or removed.
if (-not $SkipRuntimeDataBackup -and (Test-Path -LiteralPath $data -PathType Container)) {
    Write-Host "`n[3/4] Preparing runtime-data backup..."
    Copy-Item -LiteralPath $data -Destination $dataBackupTemp -Recurse
    if (-not (Test-Path -LiteralPath $dataBackupTemp -PathType Container)) {
        throw "Runtime-data backup copy could not be verified. Existing installation was not changed."
    }
}

# Switch the validated configuration into place. If a current installation
# exists, it becomes the new .bak; an older .bak is replaced only after the
# new installation is active. If no current installation exists, keep .bak.
Write-Host "`n[4/4] Installing validated configuration..."
$configMoved = $false
$currentConfigBecameBackup = $false
$oldBackupMoved = $false
$newConfigActivated = $false

try {
    if (Test-Path -LiteralPath $config) {
        Move-Item -LiteralPath $config -Destination $configRecovery
        $configMoved = $true

        if (Test-Path -LiteralPath $configBackup) {
            Move-Item -LiteralPath $configBackup -Destination $oldConfigBackup
            $oldBackupMoved = $true
        }

        Move-Item -LiteralPath $configRecovery -Destination $configBackup
        $currentConfigBecameBackup = $true
    }

    Move-Item -LiteralPath $staging -Destination $config
    $newConfigActivated = $true
} catch {
    Write-Warning "Installation switch failed. Attempting to restore the previous configuration."

    if ($newConfigActivated -and (Test-Path -LiteralPath $config)) {
        if (-not (Test-Path -LiteralPath $failedInstall)) {
            Move-Item -LiteralPath $config -Destination $failedInstall
        }
    }

    if ($currentConfigBecameBackup -and (Test-Path -LiteralPath $configBackup) -and -not (Test-Path -LiteralPath $config)) {
        Move-Item -LiteralPath $configBackup -Destination $config
    } elseif ($configMoved -and (Test-Path -LiteralPath $configRecovery) -and -not (Test-Path -LiteralPath $config)) {
        Move-Item -LiteralPath $configRecovery -Destination $config
    }

    if ($oldBackupMoved -and (Test-Path -LiteralPath $oldConfigBackup) -and -not (Test-Path -LiteralPath $configBackup)) {
        Move-Item -LiteralPath $oldConfigBackup -Destination $configBackup
    }

    throw
}

# The installation is active. Only now discard the replaced older config backup.
if (Test-Path -LiteralPath $oldConfigBackup) {
    Remove-Item -LiteralPath $oldConfigBackup -Recurse -Force
}
if (Test-Path -LiteralPath $configRecovery) {
    Remove-Item -LiteralPath $configRecovery -Recurse -Force
}

# Replace the old runtime-data backup only after the new copy has been made.
if (-not $SkipRuntimeDataBackup -and (Test-Path -LiteralPath $dataBackupTemp -PathType Container)) {
    try {
        if (Test-Path -LiteralPath $dataBackup) {
            Move-Item -LiteralPath $dataBackup -Destination $dataBackupRecovery
        }

        Move-Item -LiteralPath $dataBackupTemp -Destination $dataBackup

        if (Test-Path -LiteralPath $dataBackupRecovery) {
            Remove-Item -LiteralPath $dataBackupRecovery -Recurse -Force
        }
    } catch {
        Write-Warning "The new configuration is installed, but runtime-data backup replacement failed."
        Write-Warning "Inspect '$dataBackupTemp' and '$dataBackupRecovery' before retrying."
        Write-Warning $_.Exception.Message

        if ((Test-Path -LiteralPath $dataBackupRecovery) -and -not (Test-Path -LiteralPath $dataBackup)) {
            Move-Item -LiteralPath $dataBackupRecovery -Destination $dataBackup
        }
    }
}

Write-Host "`nInstallation completed successfully." -ForegroundColor Green
Write-Host "Configuration: $config"
if (Test-Path -LiteralPath $configBackup) {
    Write-Host "Previous configuration backup: $configBackup"
}
if (-not $SkipRuntimeDataBackup -and (Test-Path -LiteralPath $dataBackup)) {
    Write-Host "Runtime-data backup: $dataBackup"
}
Write-Host "Git metadata was retained. Start Neovim by running: nvim"
