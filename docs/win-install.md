# Windows Installation

`nvim-config` requires **Neovim 0.12.0 or later**. The project is under active development.

Windows installation is supported through the PowerShell scripts described below. Linux and macOS instructions will be added when their setup and validation procedures are ready.

## Windows

These instructions use PowerShell and Neovim's standard Windows configuration and data directories.

### 1. Install the required tools

Install the following tools and ensure they are available on your `PATH`:

- [PowerShell 7](https://github.com/PowerShell/PowerShell) or later
- [Git](https://git-scm.com/)
- [Neovim](https://neovim.io/), version 0.12.0 or later
- [ripgrep](https://github.com/BurntSushi/ripgrep)

Open PowerShell and verify that the required commands are available:

```powershell
git --version
nvim --version
rg --version
```

The dependency script and configuration installer perform their own prerequisite checks. The installer also verifies that the installed Neovim version meets the minimum requirement.

### 2. Clone the repository

Clone the repository to obtain the dependency script, installation script, and configuration files:

```powershell
git clone https://github.com/hetfs/nvim-config.git
Set-Location nvim-config
```

If you already have a local checkout, change to that directory instead. Ensure it contains the scripts described in this guide.

### 3. Install Windows dependencies

The repository provides `scripts/win-depend.ps1` to provision core Windows dependencies and optional Neovim providers.

Review the script before running it:

```powershell
Get-Content -LiteralPath .\scripts\win-depend.ps1
```

Run the dependency script:

```powershell
.\scripts\win-depend.ps1
```

Follow any instructions printed by the script. If a required dependency is missing or a package installation fails, resolve the problem before continuing.

The dependency script is separate from the configuration installer. It prepares the Windows environment; it does not replace the steps required to validate and activate the Neovim configuration.

After dependency provisioning, verify that the required commands are available:

```powershell
git --version
nvim --version
rg --version
```

### 4. Download the configuration installer

The following commands clone a fresh copy of the repository into a temporary directory. If the directory already exists, the commands remove it before cloning again.

```powershell
$ErrorActionPreference = "Stop"

$installer = Join-Path $env:TEMP "nvim-config-installer"
$repository = "https://github.com/hetfs/nvim-config.git"

# Remove an existing temporary checkout, if present.
if (Test-Path -LiteralPath $installer) {
    Write-Host "Removing existing installer checkout: $installer"
    Remove-Item -LiteralPath $installer -Recurse -Force
}

# Clone the repository.
Write-Host "Cloning the nvim-config repository..."
git clone $repository $installer

if ($LASTEXITCODE -ne 0) {
    throw "Failed to clone nvim-config. Check your network connection and Git installation."
}

# Verify that the installer script exists.
$installerScript = Join-Path $installer "scripts\winsetup.ps1"

if (-not (Test-Path -LiteralPath $installerScript -PathType Leaf)) {
    throw "Installer script not found: $installerScript"
}

Write-Host "`nRepository cloned successfully."
Write-Host "Installer script: $installerScript"
```

This step removes **only** the temporary checkout at `%TEMP%\nvim-config-installer`. It does not directly remove your active Neovim configuration, runtime data, or backups.

Review the commands before running them. If cloning fails, resolve the underlying problem before continuing.

### 5. Review and run the configuration installer

Before executing the installer, review its contents:

```powershell
Get-Content -LiteralPath $installerScript
```

After reviewing the script, run it:

```powershell
& $installerScript
```

The installer follows a staged installation process:

1. Checks the required commands, Neovim version, and installation paths.
2. Clones the repository into a separate staging directory.
3. Verifies that `init.lua` and `scripts\smoke.lua` exist.
4. Runs the configuration smoke test against the staged configuration.
5. Prepares and verifies a copy of the existing runtime data, unless backup creation is disabled.
6. Activates the validated configuration and preserves the previous configuration as a backup.
7. Replaces the runtime-data backup after the new configuration has been activated, when applicable.

The installer validates the staged configuration before changing the active configuration or refreshing existing backups. The live runtime-data directory is never moved or deleted by the installer.

If cloning or the smoke test fails, the installer stops before switching the active configuration or replacing existing backups. Inspect the error output and resolve the underlying problem before retrying. A staging directory may remain after a failed attempt to help with diagnosis.

**Important:** A fresh temporary checkout does not fix errors in the repository itself. The installer can pass its smoke test only when the committed configuration loads and satisfies the test's requirements.

The installer retains the repository's `.git` directory in the installed configuration. You can therefore inspect its history, review changes, and manage future updates with Git.

### 6. Understand the backup locations

The installer uses these standard locations when `ConfigName` is set to its default value, `nvim`.

| Path | Purpose |
| --- | --- |
| `%LOCALAPPDATA%\nvim` | Active Neovim configuration |
| `%LOCALAPPDATA%\nvim.bak` | Previous active configuration |
| `%LOCALAPPDATA%\nvim-data` | Active Neovim runtime data |
| `%LOCALAPPDATA%\nvim-data.bak` | Backup copy of the existing runtime data |

When an active configuration already exists, the installer moves it into the configuration backup location. If an older configuration backup exists, it is preserved temporarily until the new configuration has been activated.

If the runtime-data directory exists, the installer copies it to a temporary backup and checks the copied directory's file count, directory count, and total file size before proceeding. After activation, the installer replaces the previous runtime-data backup with the prepared copy.

These checks help detect incomplete copies, but they do not verify that every file's contents are identical.

Runtime data can contain plugin files, caches, logs, swap files, undo history, and other application state. Preserving a backup provides a recovery option if you need it.

To skip the runtime-data backup, run:

```powershell
& $installerScript -SkipRuntimeDataBackup
```

Use this option only if you intentionally do not want the installer to create or refresh the runtime-data backup.

**Recovery note:** If the installer reports that backup replacement or rollback failed, do not delete the referenced recovery directories. Inspect the paths reported in the warning messages before retrying.

### 7. Start Neovim

After the installer reports success, launch Neovim:

```powershell
nvim
```

Check for startup errors and verify the configuration in an interactive session.

The current stage focuses on native Neovim workflows. Plugin installation and configuration will be introduced in later stages. Installing the repository does not mean that all planned plugins are already installed or configured.

### 8. Remove the temporary installer checkout (optional)

After installation, you can remove the temporary checkout used to run the installer:

```powershell
if (Test-Path -LiteralPath $installer) {
    Remove-Item -LiteralPath $installer -Recurse -Force
}
```

This removes only the temporary checkout. It does not remove the installed configuration, its Git history, or the configuration and runtime-data backups.

You do not need to perform this cleanup manually before a future installation. Step 4 removes an existing temporary checkout automatically.

### 9. Use a custom configuration directory (optional)

By default, the installer targets `%LOCALAPPDATA%\nvim` and `%LOCALAPPDATA%\nvim-data`.

If you use a custom `NVIM_APPNAME`, Neovim may use different configuration and data directories. The installer's `ConfigName` parameter allows you to select a different directory name:

```powershell
& $installerScript -ConfigName "nvim-work"
```

For this example, the installer targets:

| Path | Purpose |
| --- | --- |
| `%LOCALAPPDATA%\nvim-work` | Active configuration |
| `%LOCALAPPDATA%\nvim-work.bak` | Previous configuration backup |
| `%LOCALAPPDATA%\nvim-work-data` | Runtime data |
| `%LOCALAPPDATA%\nvim-work-data.bak` | Runtime-data backup |

Choose a custom name only if you understand which configuration and data directories the installer will target. The installer does not automatically detect or migrate an existing custom `NVIM_APPNAME` setup.

## Current limitations

- Windows is the currently documented installation platform.
- The dependency script provisions Windows dependencies and optional Neovim providers; the exact packages and behavior are defined by `scripts/win-depend.ps1`.
- The configuration installer requires Git, Neovim 0.12.0 or later, and ripgrep to be available on `PATH`.
- Installation validates the native configuration through the repository's smoke test. It does not guarantee that every future plugin or external tool will work.
- Configuration and runtime-data backups provide recovery options, but they are not a substitute for an independent backup of important personal files.

The project follows a staged development approach: establish a reliable native foundation first, then introduce additional tools and plugins when their requirements and validation procedures are ready.

**Minimum installation. Compose the rest.**
