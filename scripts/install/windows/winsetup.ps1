# Install nvim-config on Windows.
# Run from PowerShell 7 or Windows PowerShell.
#
# The repository is cloned and smoke-tested before the active configuration
# or existing backups are changed. The installed .git directory is retained.
#
# Usage:
#   .\scripts\install.ps1
#   .\scripts\install.ps1 -SkipRuntimeDataBackup
#   .\scripts\install.ps1 -Repository "https://github.com/hetfs/nvim-config.git"

[CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [string]$Repository = "https://github.com/hetfs/nvim-config.git",

    [ValidateNotNullOrEmpty()]
    [string]$ConfigName = "nvim",

    [switch]$SkipRuntimeDataBackup
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# Resolve and validate installation paths.
# ---------------------------------------------------------------------------

$root = $env:LOCALAPPDATA

if ([string]::IsNullOrWhiteSpace($root)) {
    throw "LOCALAPPDATA is not set. Cannot determine the installation directory."
}

if (-not (Test-Path -LiteralPath $root -PathType Container)) {
    throw "LOCALAPPDATA is not an existing directory: $root"
}

if ($ConfigName -match '[\\/:*?"<>|]' -or $ConfigName -in @(".", "..")) {
    throw "ConfigName must be a simple directory name, such as 'nvim'."
}

if ([string]::IsNullOrWhiteSpace($Repository)) {
    throw "Repository cannot be empty."
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

# ---------------------------------------------------------------------------
# Helper functions.
# ---------------------------------------------------------------------------

function Test-CommandAvailable {
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    return $null -ne (
        Get-Command $Name -ErrorAction SilentlyContinue
    )
}

function Invoke-NativeCommand {
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string[]]$Arguments,

        [Parameter(Mandatory)]
        [string]$FailureMessage
    )

    & $Name @Arguments

    $exitCode = $LASTEXITCODE

    if ($exitCode -ne 0) {
        throw "$FailureMessage Exit code: $exitCode."
    }
}

function Assert-PathDoesNotExist {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (Test-Path -LiteralPath $Path) {
        throw "Safety check failed. Path already exists: $Path"
    }
}

function Get-DirectorySnapshot {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $files = @(
        Get-ChildItem -LiteralPath $Path -File -Recurse -Force
    )

    $directories = @(
        Get-ChildItem -LiteralPath $Path -Directory -Recurse -Force
    )

    $bytes = [long]0

    foreach ($file in $files) {
        $bytes += $file.Length
    }

    [pscustomobject]@{
        FileCount      = $files.Count
        DirectoryCount = $directories.Count
        TotalBytes     = $bytes
    }
}

function Restore-InstallationState {
    param(
        [Parameter(Mandatory)]
        [bool]$ConfigWasMoved,

        [Parameter(Mandatory)]
        [bool]$PreviousBackupWasMoved,

        [Parameter(Mandatory)]
        [bool]$PreviousConfigWasBackedUp,

        [Parameter(Mandatory)]
        [bool]$NewConfigWasActivated
    )

    $errors = [System.Collections.Generic.List[string]]::new()

    try {
        if ($NewConfigWasActivated -and (Test-Path -LiteralPath $config)) {
            Assert-PathDoesNotExist -Path $failedInstall
            Move-Item -LiteralPath $config -Destination $failedInstall
        }

        if (
            $PreviousConfigWasBackedUp -and
            (Test-Path -LiteralPath $configBackup) -and
            -not (Test-Path -LiteralPath $config)
        ) {
            Move-Item -LiteralPath $configBackup -Destination $config
        }
        elseif (
            $ConfigWasMoved -and
            (Test-Path -LiteralPath $configRecovery) -and
            -not (Test-Path -LiteralPath $config)
        ) {
            Move-Item -LiteralPath $configRecovery -Destination $config
        }
    }
    catch {
        $errors.Add("Could not restore the previous configuration: $($_.Exception.Message)")
    }

    try {
        if (
            $PreviousBackupWasMoved -and
            (Test-Path -LiteralPath $oldConfigBackup) -and
            -not (Test-Path -LiteralPath $configBackup)
        ) {
            Move-Item -LiteralPath $oldConfigBackup -Destination $configBackup
        }
    }
    catch {
        $errors.Add("Could not restore the previous backup: $($_.Exception.Message)")
    }

    if ($errors.Count -gt 0) {
        Write-Warning "Automatic recovery was incomplete. Do not delete the recovery directories."

        foreach ($message in $errors) {
            Write-Warning $message
        }

        Write-Warning "Configuration path: $config"
        Write-Warning "Configuration recovery: $configRecovery"
        Write-Warning "Previous backup recovery: $oldConfigBackup"
        Write-Warning "Failed installation: $failedInstall"
    }
}

# ---------------------------------------------------------------------------
# Preflight checks.
# ---------------------------------------------------------------------------

foreach ($commandName in @("git", "nvim", "rg")) {
    if (-not (Test-CommandAvailable -Name $commandName)) {
        throw "Required command '$commandName' was not found. Install it and retry."
    }
}

$nvimVersionOutput = & nvim --version
$nvimVersionExitCode = $LASTEXITCODE

if ($nvimVersionExitCode -ne 0) {
    throw "Could not determine the installed Neovim version."
}

$versionLine = $nvimVersionOutput |
    Select-Object -First 1

if ($versionLine -notmatch 'NVIM v(?<version>\d+\.\d+\.\d+)') {
    throw "Could not parse the Neovim version: $versionLine"
}

$installedVersion = [version]$Matches.version

if ($installedVersion -lt [version]"0.12.0") {
    throw "Neovim 0.12.0 or later is required. Detected: $installedVersion"
}

foreach ($path in @(
    $staging,
    $configRecovery,
    $oldConfigBackup,
    $failedInstall,
    $dataBackupTemp,
    $dataBackupRecovery
)) {
    Assert-PathDoesNotExist -Path $path
}

if (Test-Path -LiteralPath $config -PathType Leaf) {
    throw "The configuration path is a file, not a directory: $config"
}

if (Test-Path -LiteralPath $configBackup -PathType Leaf) {
    throw "The configuration backup path is a file: $configBackup"
}

if (-not $SkipRuntimeDataBackup) {
    if (Test-Path -LiteralPath $data -PathType Leaf) {
        throw "The runtime-data path is a file, not a directory: $data"
    }

    if (Test-Path -LiteralPath $dataBackup -PathType Leaf) {
        throw "The runtime-data backup path is a file: $dataBackup"
    }
}

Write-Host "Repository: $Repository"
Write-Host "Neovim version: $installedVersion"
Write-Host "Install target: $config"
Write-Host "Configuration backup: $configBackup"

if ($SkipRuntimeDataBackup) {
    Write-Host "Runtime-data backup: skipped"
}
else {
    Write-Host "Runtime-data backup: $dataBackup"
}

# ---------------------------------------------------------------------------
# Step 1: Clone the repository into a unique staging directory.
# ---------------------------------------------------------------------------

Write-Host "`n[1/4] Cloning repository..."

Invoke-NativeCommand `
    -Name "git" `
    -Arguments @("clone", "--", $Repository, $staging) `
    -FailureMessage "Git clone failed. The active configuration and backups were not changed."

# ---------------------------------------------------------------------------
# Step 2: Validate and smoke-test the staged configuration.
# ---------------------------------------------------------------------------

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
    Invoke-NativeCommand `
        -Name "nvim" `
        -Arguments @(
            "--headless",
            "-i", "NONE",
            "-u", $initFile,
            "-c", "luafile scripts/smoke.lua"
        ) `
        -FailureMessage "Smoke test failed. The active configuration and backups were not changed. Clone retained at: $staging"
}
finally {
    Pop-Location
}

# ---------------------------------------------------------------------------
# Step 3: Prepare and verify the runtime-data backup.
# The live runtime-data directory is never moved or removed.
# ---------------------------------------------------------------------------

if (
    -not $SkipRuntimeDataBackup -and
    (Test-Path -LiteralPath $data -PathType Container)
) {
    Write-Host "`n[3/4] Preparing runtime-data backup..."

    $sourceSnapshot = Get-DirectorySnapshot -Path $data

    Copy-Item `
        -LiteralPath $data `
        -Destination $dataBackupTemp `
        -Recurse `
        -Force

    if (-not (Test-Path -LiteralPath $dataBackupTemp -PathType Container)) {
        throw "Runtime-data backup was not created. The active configuration was not changed."
    }

    $backupSnapshot = Get-DirectorySnapshot -Path $dataBackupTemp

    if (
        $sourceSnapshot.FileCount -ne $backupSnapshot.FileCount -or
        $sourceSnapshot.DirectoryCount -ne $backupSnapshot.DirectoryCount -or
        $sourceSnapshot.TotalBytes -ne $backupSnapshot.TotalBytes
    ) {
        throw "Runtime-data backup verification failed. The active configuration was not changed. Inspect: $dataBackupTemp"
    }
}
else {
    Write-Host "`n[3/4] Runtime-data backup preparation skipped."
}

# ---------------------------------------------------------------------------
# Step 4: Activate the validated configuration.
# Preserve recovery paths until activation and backup replacement complete.
# ---------------------------------------------------------------------------

Write-Host "`n[4/4] Installing validated configuration..."

$configMoved = $false
$previousBackupMoved = $false
$previousConfigBackedUp = $false
$newConfigActivated = $false

try {
    if (Test-Path -LiteralPath $config) {
        Move-Item -LiteralPath $config -Destination $configRecovery
        $configMoved = $true

        if (Test-Path -LiteralPath $configBackup) {
            Move-Item -LiteralPath $configBackup -Destination $oldConfigBackup
            $previousBackupMoved = $true
        }

        Move-Item -LiteralPath $configRecovery -Destination $configBackup
        $previousConfigBackedUp = $true
    }

    Move-Item -LiteralPath $staging -Destination $config
    $newConfigActivated = $true
}
catch {
    $installationError = $_

    Write-Warning "Installation switch failed. Attempting to restore the previous configuration."

    Restore-InstallationState `
        -ConfigWasMoved $configMoved `
        -PreviousBackupWasMoved $previousBackupMoved `
        -PreviousConfigWasBackedUp $previousConfigBackedUp `
        -NewConfigWasActivated $newConfigActivated

    throw $installationError
}

# ---------------------------------------------------------------------------
# Replace the runtime-data backup only after the new configuration is active.
# ---------------------------------------------------------------------------

$dataBackupReplacementSucceeded = $true

if (
    -not $SkipRuntimeDataBackup -and
    (Test-Path -LiteralPath $dataBackupTemp -PathType Container)
) {
    try {
        if (Test-Path -LiteralPath $dataBackup) {
            Move-Item -LiteralPath $dataBackup -Destination $dataBackupRecovery
        }

        Move-Item -LiteralPath $dataBackupTemp -Destination $dataBackup

        if (Test-Path -LiteralPath $dataBackupRecovery) {
            Remove-Item -LiteralPath $dataBackupRecovery -Recurse -Force
        }
    }
    catch {
        $dataBackupReplacementSucceeded = $false

        Write-Warning "The new configuration is active, but runtime-data backup replacement failed."
        Write-Warning "Inspect these paths before retrying:"
        Write-Warning "  Temporary backup: $dataBackupTemp"
        Write-Warning "  Previous backup recovery: $dataBackupRecovery"
        Write-Warning $_.Exception.Message

        if (
            (Test-Path -LiteralPath $dataBackupRecovery) -and
            -not (Test-Path -LiteralPath $dataBackup)
        ) {
            try {
                Move-Item -LiteralPath $dataBackupRecovery -Destination $dataBackup
            }
            catch {
                Write-Warning "Could not restore the previous runtime-data backup: $($_.Exception.Message)"
            }
        }
    }
}

# ---------------------------------------------------------------------------
# Cleanup old configuration backups after activation.
# Keep recovery material if cleanup fails.
# ---------------------------------------------------------------------------

foreach ($path in @($oldConfigBackup, $configRecovery)) {
    if (Test-Path -LiteralPath $path) {
        try {
            Remove-Item -LiteralPath $path -Recurse -Force
        }
        catch {
            Write-Warning "Could not remove obsolete recovery material: $path"
            Write-Warning $_.Exception.Message
        }
    }
}

# ---------------------------------------------------------------------------
# Report the outcome.
# ---------------------------------------------------------------------------

Write-Host "`nConfiguration installation completed." -ForegroundColor Green
Write-Host "Configuration: $config"

if (Test-Path -LiteralPath $configBackup) {
    Write-Host "Previous configuration backup: $configBackup"
}

if (-not $SkipRuntimeDataBackup) {
    if (Test-Path -LiteralPath $dataBackup) {
        Write-Host "Runtime-data backup: $dataBackup"
    }

    if (-not $dataBackupReplacementSucceeded) {
        Write-Warning "Runtime-data backup replacement did not complete successfully."
    }
}

Write-Host "Git metadata was retained."
Write-Host "Start Neovim by running: nvim"

if (-not $dataBackupReplacementSucceeded) {
    throw "Configuration installed, but runtime-data backup replacement needs attention."
}
