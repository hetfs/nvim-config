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

The dependency setup script is documented in [Dependencies](docs/dependencies.md).

### Linux and macOS

Installation instructions will be added when the setup and validation procedures are documented.

## Design Principles

- **Native-first:** Prefer Neovim's built-in capabilities before adding plugins.
- **Native plugin management:** Use Neovim's built-in `vim.pack` rather than `lazy.nvim`.
- **Modularity:** Keep configuration modules focused and maintainable.
- **Explicit plugin admission:** Evaluate dependencies and alternatives before accepting a plugin.
- **Stage-aware implementation:** Introduce features only at their assigned roadmap stage.
- **Reproducibility:** Document requirements, dependencies, and architectural decisions.
- **Testability:** Validate each stage before advancing.
- **Replaceability:** Retire or replace plugins when evidence justifies the change.

## Current Stage

**Stage 04 — Native Workflows: In Progress**

Stage 04 establishes useful workflows using Neovim's built-in capabilities before introducing plugins.

Current work includes:

- Native search and quickfix integration.
- Native commenting.
- A built-in statusline.
- A native diagnostics baseline.
- A built-in terminal workflow.
- Regression tests and documentation.

The native commenting workflow remains under development. The `gcc` and `gc` mappings have not been added to `lua/config/keymaps.lua`. They must not be treated as implemented until the native commenting behavior has been verified and the mappings have been implemented and tested.

The automated smoke test covers the checks explicitly implemented in `scripts/smoke.lua`. Passing automated checks does not establish that every workflow behaves correctly during interactive use.

The terminal-mode escape mapping and native commenting workflow require interactive verification, as documented in [Native Keymap Testing](docs/Keymap-test.md).

Stage 04 will not be considered complete until the relevant automated checks pass, the documentation is reviewed, and the configuration has been validated in a real interactive session.

## Stage 05 — Native Plugin Management and Colorscheme

Stage 05 introduces Neovim's native `vim.pack` plugin manager and Catppuccin as the first explicitly approved plugin.

The implementation:

- Uses `vim.pack.add()` to install Catppuccin from its official repository.
- Configures the Catppuccin Mocha flavor.
- Keeps plugin installation and colorscheme configuration together in `lua/plugins/colorscheme.lua`.
- Loads the plugin module directly from `init.lua`, preserving the existing module-loading architecture.
- Does not introduce `lazy.nvim` or lazy-loading infrastructure.

Validation completed so far:

- Catppuccin installation completed successfully.
- Headless startup completed without errors.
- The active colorscheme was verified as `catppuccin-mocha`.
- The Catppuccin module was confirmed loaded.
- StyLua formatting and Lua syntax checks passed.
- The existing Stage 04 smoke test passed on Neovim 0.12.6.

Stage 05 remains subject to final documentation review and regression validation before it is marked complete.

## Repository Structure

```text
nvim-config/
├── init.lua
├── stylua.toml
├── README.md
├── LICENSE
├── docs/
│   ├── win-install.md
│   ├── dependencies.md
│   └── Keymap-test.md
├── lua/
│   ├── config/
│   │   ├── options.lua
│   │   ├── keymaps.lua
│   │   └── autocmds.lua
│   └── plugins/
│       └── colorscheme.lua
└── scripts/
    ├── check-syntax.lua
    ├── smoke.lua
    ├── win-depend.ps1
    └── winsetup.ps1
```

The structure will expand as later stages introduce additional responsibilities. Documentation records setup requirements, architectural decisions, and validation procedures alongside the implementation.

## Validation

Run the following commands from the repository root.

### Check Lua syntax

```powershell
nvim --headless -u NONE -l scripts/check-syntax.lua
```

The checker compiles discovered Lua files without executing their contents. It exits with status `0` if all files compile successfully and status `1` if syntax errors are found.

### Run the smoke test

```powershell
nvim --headless -u init.lua -c "luafile scripts/smoke.lua"
```

The smoke test verifies the Neovim version, representative options, leader keys, module loading, keymaps, autocommand registration, native search and quickfix behavior, and the required-module failure contract.

Additional workflow checks should be documented and included in the smoke test as their implementations become available.

A passing smoke test does not replace interactive testing.

### Verify the colorscheme

```powershell
nvim --headless -u init.lua `
  -c "lua print('colorscheme:', vim.g.colors_name)" `
  -c "lua print('catppuccin module:', package.loaded['catppuccin'] ~= nil)" `
  -c "qa!"
```

The expected values are `catppuccin-mocha` for the active colorscheme and `true` for the loaded Catppuccin module.

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

Before committing changes, review the working tree and inspect whitespace errors:

```powershell
git status --short
git diff --check
```

To review changes that have already been staged:

```powershell
git diff --cached --check
git diff --cached --stat
```

Remember that `git diff` does not include untracked files. Review new files separately before staging them.

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

The project uses Neovim's native `vim.pack` for plugin management. Lazy-loading is deferred to Stage 16 and must be validated against the minimum supported Neovim version before adoption.

## Contributing

Contributions should respect the architecture, roadmap, plugin admission policy, and testing requirements.

Changes should be focused, documented, and validated before a stage is marked complete.

## License

This project is licensed under the [MIT License](LICENSE).

Copyright (c) 2025 HETFS LIMITED
