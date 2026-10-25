# nvim-config

A native-first, modular Neovim configuration built incrementally around Neovim's built-in capabilities.

> **Minimum installation. Compose the rest.**

The project prioritizes a minimal installation, explicit plugin evaluation, reproducible setup, and stage-by-stage validation.

## Requirements

- Neovim >= 0.12.0
- [Git](https://git-scm.com/) (`git`)
- [ripgrep](https://github.com/BurntSushi/ripgrep) (`rg`) for native search workflows
- [fd](https://github.com/sharkdp/fd) for file and directory discovery
- [fzf](https://github.com/junegunn/fzf) for the independent `fzf-lua` fuzzy-finding workflow

Additional requirements depend on the implemented workflows:

- **Tree-sitter:** Tree-sitter CLI, GNU tar, and a compatible C compiler for parser installation and compilation.
- **LSP:** `lua-language-server` for the current Lua language-server integration.
- **Formatting:** StyLua for formatting checks and maintenance.

The Windows setup procedure uses WinGet to install missing dependencies when available. It verifies the Tree-sitter CLI and configures the WinLibs GCC/G++ toolchain.

See [Dependencies](docs/dependencies.md) for the dependency policy, setup script, and verification details.

Additional tools and providers are introduced only when required by an implemented workflow. Some integrations have optional runtime or provider requirements.

## Installation

`nvim-config` requires **Neovim 0.12.0 or later** and is under active development.

### Windows

For the Windows installation procedure, including dependency setup, configuration installation, backups, and optional settings, see the [Windows installation guide](docs/win-install.md).

The dependency setup script and external requirements are documented in [Dependencies](docs/dependencies.md).

### Linux and macOS

Installation and validation instructions for Linux and macOS have not yet been documented. The Windows guide should not be treated as a cross-platform installation procedure.

## Design Principles

- **Native-first:** Prefer Neovim's built-in capabilities before adding plugins.
- **Native plugin management:** Use Neovim's built-in `vim.pack` rather than `lazy.nvim`.
- **Modularity:** Keep configuration modules focused and maintainable.
- **Explicit plugin admission:** Evaluate necessity, dependencies, maintenance, and alternatives before accepting a plugin.
- **Stage-aware implementation:** Introduce features at their assigned roadmap stage.
- **Reproducibility:** Document requirements, dependencies, and architectural decisions.
- **Testability:** Validate each implementation and preserve regression coverage.
- **Replaceability:** Retire or replace plugins when evidence justifies the change.
- **Explicit activation:** Installing a shared plugin repository does not automatically enable every module it provides.
- **Direct loading:** Keep configuration module loading explicit in `init.lua`.
- **Behavior-based verification:** Distinguish successful registration and configuration checks from verified interactive behavior.

## Current Status

The project follows a 17-stage roadmap. Stages 05, 06, 08, and 09 have completed implementation and validation. Stage 07's navigation and editing workflows have been implemented and interactively tested. Stage 10's automated validation has passed, and Blink completion has been verified interactively.

**Stage 04 remains in progress** because native commenting is unresolved. Stage 10 still requires explicit interactive verification of snippet expansion and navigation, automatic pairing behavior, and relevant regressions before its acceptance criteria can be considered fully satisfied.

Later stages may be developed and validated independently without treating unfinished earlier work as complete.

### Stage 01 — First Init

Establishes the initial configuration entry point and the project's foundational startup behavior.

### Stage 02 — Keymaps and Autocommands

Introduces the initial native options, project keymaps, and autocommands, with syntax checks and smoke-test coverage.

### Stage 03 — Modules

Organizes the configuration into focused modules while preserving explicit loading from the root `init.lua`.

The root entry point remains responsible for resolving the configuration root, checking the supported Neovim version, and loading required modules directly.

### Stage 04 — Native Workflows

**Status: In progress — native commenting unresolved**

Stage 04 establishes useful workflows using Neovim's built-in capabilities before introducing plugins.

The scope includes:

- Native search and quickfix integration.
- Native commenting.
- A built-in statusline.
- A native diagnostics baseline.
- A built-in terminal workflow.
- Regression tests and documentation.

Neovim provides native commenting mappings:

- `gcc` — toggle commenting on the current line.
- `gc` followed by a motion — toggle commenting over the motion.
- Visual selection followed by `gc` — toggle commenting on the selection.

The current investigation identified a discrepancy: `gcc` worked in `nvim --clean` but left a line unchanged in the configured session. Visual-mode commenting also behaved unexpectedly. The root cause has not been established.

The terminal-mode Escape workflow has been interactively verified. Native commenting remains unresolved and must not be marked functional based solely on mapping registration or a passing smoke-test assertion.

The testing procedure and diagnostic findings are documented in [Native Keymap and Interactive Workflow Testing](docs/Keymap-test.md).

Stage 04 remains open until line and selection commenting have been investigated and verified.

### Stage 05 — Native Plugin Management and Colorscheme

**Status: Complete**

Stage 05 introduced Neovim's native `vim.pack` plugin manager and Catppuccin as the first explicitly approved plugin.

The implementation:

- Uses `vim.pack.add()` to install Catppuccin from its official repository.
- Configures the Catppuccin Mocha flavor.
- Keeps plugin installation and colorscheme configuration in `lua/plugins/colorscheme.lua`.
- Loads the module directly from `init.lua`.
- Does not introduce `lazy.nvim` or lazy-loading infrastructure.

Validation confirmed successful installation, headless startup, the active `catppuccin-mocha` colorscheme, and the loaded Catppuccin module. StyLua formatting, Lua syntax checks, and the smoke test passed on Neovim 0.12.6.

Stage 05 remains part of the regression baseline for subsequent stages.

### Stage 06 — Keymap Discovery and Icons

**Status: Complete**

Stage 06 introduced `which-key.nvim` for keymap discovery and `mini.icons` for icon support.

The implementation:

- Installs `which-key.nvim` using `vim.pack`.
- Installs the shared `mini.nvim` repository once.
- Activates `mini.icons` explicitly without automatically enabling unrelated modules.
- Configures keymap groups for discovery.
- Keeps plugin configuration modular in `lua/plugins/which-key.lua` and `lua/plugins/icons.lua`.
- Preserves direct module loading from `init.lua`.

Validation confirmed successful plugin loading, passing syntax and formatting checks, and a passing Stage 06 smoke test on Neovim 0.12.6.

Additional `mini.nvim` modules are activated explicitly at their assigned stages.

### Stage 07 — Navigation and Editing Workflows

**Status: Implementation validated; interactive checks reported passed**

Stage 07 introduces navigation and editing tools while preserving native Neovim capabilities and the explicit plugin admission policy.

The implementation includes:

- **Snacks.nvim:** Picker and Explorer for file discovery, content search, buffer selection, and directory navigation.
- **fzf-lua:** An independent fuzzy-finding workflow with its own configuration and keymaps.
- **flash.nvim:** Enhanced motion and search navigation.
- **Selected `mini.nvim` modules:** `mini.ai`, `mini.surround`, and `mini.move`.
- **dial.nvim:** Increment and decrement operations for supported values and selections.
- **which-key integration:** Keymap discovery for the configured workflows.

The implementation keeps Snacks Picker and `fzf-lua` configuration and mappings independent. The Snacks dashboard remains deferred to Stage 15.

External navigation dependencies include `fd` and `fzf`. Their installation and verification are handled by `scripts/win-depend.ps1` on Windows.

Validation has included:

- Successful plugin registration and loading in the smoke test.
- Lua syntax and StyLua formatting checks.
- Regression checks for native search, quickfix, and the required-module failure contract.
- Interactive checks of the navigation and editing workflows, including Flash mappings, Snacks pickers and Explorer, fzf-lua, selected `mini.nvim` modules, dial.nvim, which-key, and existing mapping behavior.

The reported interactive checks passed. Preserve these checks as the regression baseline for future plugin updates and keymap changes.

Plugins introduced before Stage 16 remain eagerly loaded under the current policy. Lazy-loading is not part of Stage 07.

### Stage 08 — Tree-sitter

**Status: Complete**

Stage 08 introduces Tree-sitter-based syntax parsing and highlighting while keeping parser installation separate from plugin installation and configuration.

The implementation:

- Installs `nvim-treesitter` using Neovim's native `vim.pack` plugin manager.
- Keeps plugin configuration in `lua/plugins/treesitter.lua`.
- Loads the module directly from `init.lua`.
- Configures the parser and query installation directory under Neovim's data directory.
- Enables native Tree-sitter highlighting for Lua buffers through `vim.treesitter.start()`.
- Uses an explicit `FileType` autocommand for Lua.
- Preserves eager plugin loading and does not introduce lazy-loading infrastructure.

The Windows dependency setup script checks the external prerequisites needed for parser installation and compilation:

- GNU tar bundled with Git for Windows.
- WinLibs GCC/G++ POSIX UCRT toolchain.
- Tree-sitter CLI version 0.26.1 or later.
- cURL for network transfers.

The script places the verified compiler directory on the current process's `PATH` and sets `CC` to the selected GCC executable. These environment changes apply to the current PowerShell process and its child processes; they are not persisted as Windows environment settings.

Validation confirmed:

- Successful Windows dependency and provider checks.
- Successful compiler and Tree-sitter CLI verification.
- Successful parser installation and Lua highlighting.
- Passing StyLua formatting checks.
- Passing Lua syntax checks across 17 Lua files at the time of validation.
- Passing smoke-test and whitespace checks before the stage was committed.

Stage 08 does not automatically enable Tree-sitter-based indentation, folding, LSP, completion, formatting, or linting. These remain separate features for their assigned stages.

### Stage 09 — LSP and lazydev

**Status: Complete**

Stage 09 integrates Neovim's native Language Server Protocol client with LuaLS.

The implementation:

- Installs `nvim-lspconfig` using Neovim's native `vim.pack`.
- Installs and configures `lazydev.nvim` to improve LuaLS awareness of Neovim and installed Lua libraries.
- Uses Neovim's native `vim.lsp.config` and `vim.lsp.enable` APIs.
- Keeps shared LSP attachment behavior in `lua/config/lsp.lua`.
- Keeps Lua language-server configuration in the project-local language pack `lua/langs/lua.lua`.
- Discovers language packs from the project's own `lua/langs/` directory.
- Registers `gd` and `gD` as buffer-local mappings when an LSP client attaches.
- Uses an externally installed `lua-language-server`; Mason is not part of the default setup.
- Preserves direct module loading and eager plugin loading.

The LuaLS configuration recognizes `vim` as a global, disables third-party workspace prompts, and disables telemetry.

Automated smoke tests confirmed the LSP and language-pack configuration contract. Interactive testing confirmed that LuaLS attached to a Lua buffer and that definition navigation and hover worked. Declaration navigation did not work in the tested case; this result depends on the symbol and server response and should not be interpreted as proof that all declaration requests fail.

Diagnostics and non-LSP buffer isolation remain separate verification items. The completed Stage 09 implementation and its automated checks are recorded in the project history.

### Stage 10 — Completion and Snippets

**Status: Implementation validated; interactive verification in progress**

Stage 10 introduces completion, snippet integration, and automatic bracket and quote pairing while retaining Neovim's native snippet functionality.

The implementation includes:

- **blink.cmp:** Completion engine installed through Neovim's native `vim.pack`.
- **friendly-snippets:** Snippet collection registered as a separate plugin.
- **Native `vim.snippet`:** Snippet expansion and navigation.
- **mini.pairs:** Automatic bracket and quote pairing, activated from the existing `mini.nvim` installation.

The configured Blink completion sources are:

- LSP
- Filesystem paths
- Snippets
- Words from the current buffer

The implementation uses Blink's Lua fuzzy-search implementation and its default keymap preset. Completion documentation is not shown automatically.

The implementation deliberately avoids LuaSnip, nvim-cmp, and Mason. The native snippet API remains responsible for expansion and navigation, while `friendly-snippets` supplies snippet definitions.

All plugins continue to load eagerly. Lazy-loading remains deferred to Stage 16.

Validation confirmed:

- Successful StyLua formatting checks.
- Successful `git diff --check`.
- Passing syntax and configured smoke tests on Neovim 0.12.6.
- Successful module-loading and API assertions for Blink, native snippets, and `mini.pairs`.
- Active registration of `friendly-snippets`.
- Interactive completion behavior, including candidate display, navigation, and acceptance.

Snippet discovery and expansion, placeholder navigation, the complete automatic-pairing workflow, and related mapping regressions still require explicit interactive verification.

A passing smoke test establishes only the assertions it performs. Stage 10 must not be considered fully verified until the remaining interactive checks have been recorded.

### Future Stages

The remaining roadmap is:

- **Stage 11 — Format and Lint:** Formatting and linting integrations.
- **Stage 12 — Git, Root, and Sessions:** Git workflows, project-root behavior, and session management.
- **Stage 13 — Language Packs:** Additional language-specific configuration.
- **Stage 14 — Debugging:** Debug Adapter Protocol integration.
- **Stage 15 — UI Polish:** Dashboard and other deferred interface enhancements.
- **Stage 16 — Performance:** Evaluate lazy-loading and performance improvements with validation against the minimum supported Neovim version.
- **Stage 17 — Hardening:** Final reliability, testing, and CI improvements.

Features are introduced only when their assigned stages are reached and their dependencies and acceptance criteria have been evaluated.

## Repository Structure

The repository's configuration and plugin modules are organized by responsibility.

```text
nvim-config/
├── init.lua
├── .editorconfig
├── .gitattributes
├── stylua.toml
├── README.md
├── LICENSE
├── docs/
│   ├── win-install.md
│   ├── dependencies.md
│   ├── Keymap-test.md
│   ├── architecture.md
│   ├── roadmap.md
│   ├── plugin-inventory.md
│   ├── plugin-admission-policy.md
│   ├── dependencies.md
│   ├── keymaps.md
│   ├── lsp.md
│   └── decisions/
├── lua/
│   ├── config/
│   │   ├── options.lua
│   │   ├── keymaps.lua
│   │   ├── autocmds.lua
│   │   └── lsp.lua
│   ├── langs/
│   │   ├── init.lua
│   │   └── lua.lua
│   └── plugins/
│       ├── colorscheme.lua
│       ├── icons.lua
│       ├── which-key.lua
│       ├── snacks.lua
│       ├── fzf-lua.lua
│       ├── flash.lua
│       ├── mini-ai.lua
│       ├── mini-surround.lua
│       ├── mini-move.lua
│       ├── dial.lua
│       ├── treesitter.lua
│       ├── lsp.lua
│       ├── lazydev.lua
│       ├── blink-cmp.lua
│       ├── friendly-snippets.lua
│       └── mini-pairs.lua
└── scripts/
    ├── check-syntax.lua
    ├── smoke.lua
    ├── win-depend.ps1
    └── winsetup.ps1
```

This tree illustrates the project's organization. Some documentation files and decision records may differ from the current checkout, and future stages may add more modules, documentation, and tests. Use `git status --short` and the actual repository contents when reviewing the project.

## Validation

Run the following commands from the repository root. The examples use PowerShell, matching the documented Windows setup.

### Check Lua syntax

```powershell
nvim --headless -u NONE -l scripts/check-syntax.lua
```

The checker compiles discovered Lua files without executing their contents. It exits with status `0` when all checked files compile successfully and a nonzero status when syntax errors are found.

### Run the smoke test

```powershell
nvim --headless -u init.lua -c "luafile scripts/smoke.lua"
```

The smoke test verifies the Neovim version, representative options, leader keys, module loading, keymaps, autocommand registration, native search and quickfix behavior, and the required-module failure contract. It also checks plugin registration and workflow behavior explicitly implemented in the test suite.

The Stage 10 assertions cover completion, snippets, and pairing configuration. They do not replace interactive tests of actual editing behavior.

A passing smoke test does not establish that every workflow behaves correctly during interactive use.

### Verify the colorscheme

```powershell
nvim --headless -u init.lua `
  -c "lua print('colorscheme:', vim.g.colors_name)" `
  -c "lua print('catppuccin module:', package.loaded['catppuccin'] ~= nil)" `
  -c "qa!"
```

Expected values:

- Active colorscheme: `catppuccin-mocha`
- Loaded Catppuccin module: `true`

### Verify Tree-sitter

First, confirm that the external dependencies are available in the current PowerShell session:

```powershell
gcc --version
g++ --version
tree-sitter --version
tar --version
$env:CC
```

Then open a Lua file in Neovim and inspect a syntax token:

```vim
:Inspect
```

Tree-sitter highlighting must be verified in a buffer with the Lua parser installed. External dependency checks alone do not prove that parser installation, highlighting, or queries work correctly.

### Verify LSP

Confirm that the external Lua language server is available:

```powershell
Get-Command lua-language-server
```

Open a Lua file using the project configuration and verify that LuaLS attaches. Test definition navigation, hover, diagnostics, and buffer-local mapping behavior as described in [Native Keymap and Interactive Workflow Testing](docs/Keymap-test.md).

A registered LSP configuration is not proof that the server started or attached successfully.

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

Before committing, review both the working tree and staged changes:

```powershell
git status --short
git diff --check
git diff --cached --check
git diff --cached --stat
```

`git diff --check` checks unstaged tracked changes. `git diff --cached --check` checks staged changes. Neither command includes untracked files until they are staged.

Review the actual contents of new files and the complete staged diff before committing. Line-ending warnings should be distinguished from whitespace errors; `.gitattributes` defines repository line-ending behavior.

Run syntax, smoke, formatting, and diff checks after changes. Test new interactive workflows in a real Neovim session before marking their stage complete.

## Roadmap

1. First Init — Complete
2. Keymaps and Autocommands — Complete
3. Modules — Complete
4. Native Workflows — **In progress**
5. `vim.pack` and Catppuccin — Complete
6. which-key and `mini.icons` — Complete
7. Navigation and Editing Workflows — **Implementation validated**
8. Tree-sitter — Complete
9. LSP and lazydev — Complete
10. Completion and Snippets — **Interactive verification in progress**
11. Format and Lint
12. Git, Root, and Sessions
13. Language Packs
14. Debugging
15. UI Polish
16. Performance
17. Hardening

Stage status reflects implementation and available validation evidence. A stage must satisfy its acceptance criteria before it is marked complete. Independent later stages may be developed while an earlier stage remains in progress, provided architecture and regression checks are preserved.

## Plugin Policy

A plugin is not accepted merely because it is popular or appears in another Neovim distribution.

Candidates must be evaluated for:

- Necessity and native alternatives.
- Maintenance and compatibility.
- Dependencies and external executables.
- Architectural fit.
- Configuration complexity and replaceability.

Accepted plugins may be deferred to their assigned stage. Plugins may also be retired or replaced when evidence justifies the change.

The project uses Neovim's native `vim.pack` for plugin management. Lazy-loading is deferred to Stage 16 and must be validated against the minimum supported Neovim version before adoption.

Plugin installation, module activation, and feature configuration are explicit decisions. Installing a shared plugin repository does not automatically enable all modules it provides.

## Contributing

Contributions should respect the architecture, roadmap, plugin admission policy, and testing requirements.

Keep changes focused, document relevant decisions, run the appropriate automated checks, and verify interactive behavior before marking a stage complete.

## License

This project is licensed under the [MIT License](LICENSE).

Copyright (c) 2025 HETFS LIMITED

