# nvim-config

A native-first, modular Neovim configuration built incrementally around Neovim's built-in capabilities.

> **Minimum installation. Compose the rest.**

The project prioritizes a minimal installation, explicit plugin evaluation, reproducible setup, and stage-by-stage validation.

## Requirements

- Neovim >= 0.12.0
- Git
- A supported operating system and shell
- [ripgrep](https://github.com/BurntSushi/ripgrep) (`rg`) for the native search workflow

Additional external tools will be documented as the stages that require them are implemented.

## Installation

`nvim-config` requires **Neovim 0.12.0 or later**. The project is under active development.

Windows installation is supported by the PowerShell installer described below. Linux and macOS instructions will be added when their setup and validation procedures are ready.

### Windows

These instructions use PowerShell and Neovim's standard Windows configuration and data directories.

#### 1. Install the required tools

Install the following tools and ensure they are available on your `PATH`:

- [Neovim](https://neovim.io/) 0.12.0 or later
- [Git](https://git-scm.com/)
- [ripgrep](https://github.com/BurntSushi/ripgrep)

Verify that PowerShell can find them:

```powershell
git --version
nvim --version
rg --version
```

The installer checks for these commands before proceeding.

#### 2. Download the installer

The following PowerShell commands automatically remove an existing temporary installer checkout before cloning the repository again. You can repeat this step after a previous installation attempt without manually deleting the temporary directory.

```powershell
$ErrorActionPreference = "Stop"

$installer = Join-Path $env:TEMP "nvim-config-installer"
$repository = "https://github.com/hetfs/nvim-config.git"

# Remove the existing temporary installer checkout, if present.
if (Test-Path -LiteralPath $installer) {
    Write-Host "Removing existing installer checkout: $installer"
    Remove-Item -LiteralPath $installer -Recurse -Force
}

# Clone a fresh copy of the repository.
Write-Host "Cloning the latest nvim-config repository..."
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

If cloning fails, PowerShell stops and reports the error. Resolve the problem before continuing.

#### 3. Review and run the installer

Before executing the installer, review its contents:

```powershell
Get-Content -LiteralPath $installerScript
```

After reviewing the script, run it:

```powershell
& $installerScript
```

The installer performs the following operations:

1. Checks that required commands and installation paths are available.
2. Clones the repository into a separate staging directory.
3. Verifies that `init.lua` and `scripts\smoke.lua` exist.
4. Runs the configuration smoke test.
5. Switches the validated configuration into the active configuration directory.
6. Prepares and replaces the runtime-data backup when applicable.

The installer validates the staged configuration before replacing the active configuration or refreshing the existing backups.

If cloning or the smoke test fails, the installer stops before making those changes. A failed staging clone is retained for diagnosis; inspect the error output and resolve the underlying problem before retrying.

The installer retains the repository's `.git` directory in the installed configuration. You can therefore use Git to inspect changes and receive future updates.

**Important:** A fresh temporary checkout does not fix errors in the repository itself. The installer can only pass its smoke test when the committed configuration is syntactically valid and meets the test's requirements.

#### 4. Understand the backup locations

The installer uses these standard locations:

| Path | Purpose |
| --- | --- |
| `%LOCALAPPDATA%\nvim` | Active Neovim configuration |
| `%LOCALAPPDATA%\nvim.bak` | Backup of the configuration that was active before the latest successful installation |
| `%LOCALAPPDATA%\nvim-data` | Active Neovim runtime data |
| `%LOCALAPPDATA%\nvim-data.bak` | Backup copy of the existing runtime data |

When an active configuration already exists, the installer preserves it as the new configuration backup. An older configuration backup is retained until the new configuration has been activated.

If the runtime-data directory exists, the installer **copies** it to prepare a backup rather than moving or deleting the live directory. The previous runtime-data backup is replaced only after the new copy has been prepared.

Runtime data can contain plugin files, caches, logs, swap files, undo history, and other application state. Keeping a backup provides a recovery option if you need it.

To skip the runtime-data backup, run:

```powershell
& $installerScript -SkipRuntimeDataBackup
```

Use this option only if you intentionally do not want the installer to refresh the runtime-data backup.

#### 5. Start Neovim

After the installer reports success, launch Neovim:

```powershell
nvim
```

Check for startup errors and verify the configuration in an interactive session.

The current stage focuses on native Neovim workflows. Plugin installation and configuration will be introduced in later stages; installing the repository does not mean all planned plugins are already installed or configured.

#### 6. Remove the temporary installer checkout (optional)

After installation, you can remove the temporary checkout used to run the installer:

```powershell
if (Test-Path -LiteralPath $installer) {
    Remove-Item -LiteralPath $installer -Recurse -Force
}
```

This removes only the temporary checkout. It does not remove the installed configuration, its Git history, or the configuration and runtime-data backups.

You do not need to perform this cleanup manually before a future installation. Step 2 handles an existing temporary checkout automatically.

#### 7. Custom configuration directory (optional)

These instructions use Neovim's standard Windows configuration directory.

If you use a custom `NVIM_APPNAME`, Neovim may use a different configuration and data directory. The installer defaults to `nvim` and `nvim-data` under `%LOCALAPPDATA%`. Its `ConfigName` parameter can change the directory name used by the installer:

```powershell
& $installerScript -ConfigName "nvim-work"
```

Choose a custom name only if you understand which configuration and data directories the installer will target. The installer does not automatically detect and migrate an existing custom `NVIM_APPNAME` setup.

### Linux and macOS

Installation instructions for Linux and macOS will be added when their setup and validation procedures are documented.

## Design Principles

- **Native-first:** Prefer Neovim's built-in capabilities before adding plugins.
- **Native plugin management:** Use Neovim's native `vim.pack` rather than `lazy.nvim` when plugin management is introduced.
- **Modularity:** Keep modules and plugin specifications focused.
- **Explicit plugin admission:** Evaluate dependencies before accepting them.
- **Stage-aware implementation:** Introduce features only at their assigned stage.
- **Reproducibility:** Document requirements, dependencies, and decisions.
- **Testability:** Validate each stage before advancing.
- **Replaceability:** Retire or replace plugins when evidence justifies doing so.

## Current Stage

**Stage 04 — Native Workflows: In Progress**

This stage establishes useful workflows using Neovim's built-in capabilities before introducing plugins.

Current work includes:

- Native search and quickfix integration.
- Native commenting.
- A built-in statusline.
- A native diagnostics baseline.
- A built-in terminal workflow.
- Regression tests and documentation.

The automated smoke test is intended to verify native grep and quickfix behavior, native commenting, representative options and mappings, autocommand registration, and the required-module failure contract.

Stage 04 will not be considered complete until the relevant automated checks pass, the documentation is reviewed, and the configuration has been validated in a real interactive session.

## Repository Structure

```text
nvim-config/
├── init.lua
├── stylua.toml
├── README.md
├── lua/
│   └── config/
│       ├── options.lua
│       ├── keymaps.lua
│       └── autocmds.lua
└── scripts/
    ├── check-syntax.lua
    ├── smoke.lua
    └── winsetup.ps1
```

The structure will expand as later stages introduce additional responsibilities.

## Validation

Run the following commands from the repository root.

### Check Lua syntax

```powershell
nvim --headless -l scripts/check-syntax.lua
```

The checker compiles discovered Lua files without executing their contents. It exits with status `0` if all files compile successfully and status `1` if syntax errors are found.

### Run the smoke test

```powershell
nvim --headless -u init.lua -c "luafile scripts/smoke.lua"
```

The smoke test verifies the Neovim version, representative options, leader keys, module loading, keymaps, autocommand registration, native search and quickfix behavior, native commenting, and the required-module failure contract.

### Check formatting

Install [StyLua](https://github.com/JohnnyMorganz/StyLua) separately, then run:

```powershell
stylua --check .
```

To apply formatting after making changes:

```powershell
stylua .
```

### Check the Git diff

Before committing changes, review the staged diff:

```powershell
git diff --cached --check
git diff --cached --stat
git status --short
```

Run the syntax check, smoke test, formatting check, and Git diff check after making changes.

Automated tests do not replace interactive validation. Test new workflows in a real Neovim session before marking a stage complete.

## Roadmap

1. First Init
2. Keymaps and Autocommands
3. Modules
4. Native Workflows
5. `vim.pack` and Catppuccin
6. which-key and `mini.icons`
7. Snacks Navigation
8. Treesitter
9. LSP
10. Completion and Snippets
11. Format and Lint
12. Git, Root, and Sessions
13. Language Packs
14. Debugging
15. UI Polish
16. Performance
17. Hardening

Each stage must meet its acceptance criteria before the project advances.

## Plugin Policy

A plugin is not accepted merely because it is popular or appears in another Neovim distribution.

Candidates must be evaluated for necessity, maintenance, compatibility, dependencies, architectural fit, and alternatives.

Accepted plugins may be deferred to their assigned stage. Plugins may also be retired or replaced when evidence justifies the change.

The project plans to use Neovim's native `vim.pack` rather than `lazy.nvim`.

## Contributing

Contributions should respect the architecture, roadmap, plugin admission policy, and testing requirements.

Changes should be focused, documented, and validated before a stage is marked complete.

## License

A license has not yet been established. Add a `LICENSE` file before distributing the project under an open-source license.

