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

`nvim-config` requires **Neovim 0.12.0 or later**. The project is under active development. Windows instructions are provided below; Linux and macOS instructions will be added when their setup and validation procedures are ready.

### Windows

These instructions use PowerShell and Neovim's standard configuration directory.

#### 1. Back up your existing configuration

If you already have a Neovim configuration, back it up before installing this project.

```powershell
$config = "$env:LOCALAPPDATA\nvim"
$backup = "$env:LOCALAPPDATA\nvim.bak"

if (Test-Path $config) {
    if (Test-Path $backup) {
        throw "Backup already exists at $backup. Rename it or choose another backup location."
    }

    Move-Item $config $backup
}
```

**Optional:** Back up your existing Neovim data directory if you want to preserve it separately before testing the new configuration.

```powershell
$data = "$env:LOCALAPPDATA\nvim-data"
$dataBackup = "$env:LOCALAPPDATA\nvim-data.bak"

if (Test-Path $data) {
    if (Test-Path $dataBackup) {
        throw "Backup already exists at $dataBackup. Rename it or choose another backup location."
    }

    Move-Item $data $dataBackup
}
```

The data directory may contain plugin files, caches, and other application state. Moving it preserves the backup but gives the new configuration a clean data directory.

#### 2. Install the required tools

Ensure Git, Neovim 0.12.0 or later, and ripgrep are installed and available on your `PATH`.

Verify the installations:

```powershell
git --version
nvim --version
rg --version
```

#### 3. Clone the repository

Clone `nvim-config` into Neovim's standard Windows configuration directory:

```powershell
git clone https://github.com/hetfs/nvim-config.git "$env:LOCALAPPDATA\nvim"
```

Keep the repository's Git history if you want to receive updates from the original project.

**Optional:** If you want to manage the configuration independently, you can remove the cloned repository's Git metadata:

```powershell
Remove-Item "$env:LOCALAPPDATA\nvim\.git" -Recurse -Force
```

This removes the cloned Git history and remote connection while leaving the configuration files intact. You will no longer be able to pull updates from the original repository using that clone.

#### 4. Start Neovim

Launch Neovim:

```powershell
nvim
```

Check for startup errors and verify the configuration in an interactive session.

The current stage focuses on native Neovim workflows. Plugin installation and configuration will be introduced in later stages; cloning the repository does not imply that all planned plugins are installed or configured.

#### 5. Custom configuration directory (optional)

These instructions use Neovim's standard Windows configuration directory. If you use a custom `NVIM_APPNAME`, Neovim may use a different configuration and data directory. Adjust the installation path accordingly.

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
    └── smoke.lua
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

