
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

Clone the repository into a temporary directory so you can review and run its Windows installer without modifying your existing Neovim configuration first.

```powershell
$installer = Join-Path $env:TEMP "nvim-config-installer"

if (Test-Path -LiteralPath $installer) {
    throw "Installer directory already exists at $installer. Remove or rename it before continuing."
}

git clone https://github.com/hetfs/nvim-config.git $installer

if ($LASTEXITCODE -ne 0) {
    throw "Failed to clone nvim-config."
}
```

Review the installer before running it:

```powershell
Get-Content (Join-Path $installer "scripts\winsetup.ps1")
```

#### 3. Run the installer

Run the installation script:

```powershell
& (Join-Path $installer "scripts\winsetup.ps1")
```

The installer clones the repository into a staging directory under `%LOCALAPPDATA%`, validates the required files, and runs the configuration smoke test before switching the active configuration.

If validation fails, the installer stops before replacing the active configuration or refreshing its backups.

The installer retains the repository's `.git` directory in the installed configuration. You can therefore use Git to inspect changes and receive future updates.

#### 4. Understand the backups

The installer uses these standard locations:

| Path | Purpose |
| --- | --- |
| `%LOCALAPPDATA%\nvim` | Active Neovim configuration |
| `%LOCALAPPDATA%\nvim.bak` | Backup of the previously active configuration |
| `%LOCALAPPDATA%\nvim-data` | Active Neovim runtime data |
| `%LOCALAPPDATA%\nvim-data.bak` | Backup copy of the existing runtime data |

When an existing configuration is present, the installer replaces the previous configuration backup with the configuration that was active immediately before the successful installation. An older backup is retained until the new configuration has been activated.

If the runtime data directory exists, the installer **copies** it to prepare a backup rather than moving or deleting the live directory. The previous runtime-data backup is replaced only after the new copy has been prepared.

Runtime data can contain plugin files, caches, logs, swap files, undo history, and other application state. Preserving a copy allows you to recover data if needed.

To skip the runtime-data backup, run:

```powershell
& (Join-Path $installer "scripts\winsetup.ps1") -SkipRuntimeDataBackup
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
Remove-Item -LiteralPath (Join-Path $env:TEMP "nvim-config-installer") -Recurse -Force
```

This removes only the temporary checkout. It does not remove the installed configuration or its Git history under `%LOCALAPPDATA%\nvim`.

#### 7. Custom configuration directory (optional)

These instructions use Neovim's standard Windows configuration directory.

If you use a custom `NVIM_APPNAME`, Neovim may use a different configuration and data directory. The installer currently targets the standard `nvim` and `nvim-data` directories unless its `ConfigName` parameter is changed.

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

The automated smoke test currently verifies native grep and quickfix behavior, native commenting, representative options and mappings, autocommand registration, and the required-module failure contract.

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
