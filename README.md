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

`nvim-config` requires **Neovim 0.12.0 or later** and is under active development.

### Windows

For the complete Windows installation procedure, including dependency setup, installer execution, backups, and optional configuration settings, see the [Windows installation guide](docs/win-install.md).

### Linux and macOS

Installation instructions will be added when the setup and validation procedures are documented.

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
├── docs/
│   └── win-install.md
├── lua/
│   └── config/
│       ├── options.lua
│       ├── keymaps.lua
│       └── autocmds.lua
└── scripts/
    ├── check-syntax.lua
    ├── smoke.lua
    ├── win-depend.ps1
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
