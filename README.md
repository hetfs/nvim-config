# nvim-config

A native-first, modular Neovim configuration built incrementally around Neovim's built-in capabilities.

> **Minimum installation. Compose the rest.**

The project prioritizes a minimal installation, explicit plugin evaluation, reproducible setup, and stage-by-stage validation.

## Requirements

- [Neovim](https://neovim.io/doc/install/) 0.12.0 or later.
- [Git](https://git-scm.com/)
- [ripgrep](https://github.com/BurntSushi/ripgrep) `rg` for native search workflows.
- [fd](https://github.com/sharkdp/fd) for file and directory discovery.
- [fzf](https://github.com/junegunn/fzf) for the independent `fzf-lua` fuzzy-finding workflow.

Additional requirements depend on the implemented workflows:

- **Tree-sitter:** Tree-sitter CLI, GNU tar, and a compatible C compiler for parser installation and compilation.
- **LSP:** `lua-language-server` for the current Lua language-server integration.
- **Formatting:** StyLua for Lua formatting and repository formatting checks. Conform provides the Neovim-side formatting interface; it does not install formatter executables.

On Windows, the dependency setup procedure uses WinGet to install missing dependencies when available, verifies the Tree-sitter CLI, and configures the WinLibs GCC/G++ toolchain.

See [Dependencies](docs/dependencies.md) for dependency policy, setup, and verification details.

## Installation

`nvim-config` requires **Neovim 0.12.0 or later** and remains under active development.

### Windows

For dependency setup, configuration installation, backups, and optional settings, follow the [Windows installation guide](docs/win-install.md).

### Linux and macOS

Installation and validation instructions for Linux and macOS have not yet been documented. The Windows guide is not a cross-platform installation procedure.

## Design principles

- **Native-first:** Prefer Neovim's built-in capabilities before adding plugins.
- **Native plugin management:** Use Neovim's built-in `vim.pack`, not `lazy.nvim`.
- **Modularity:** Keep configuration modules focused and maintainable.
- **Explicit plugin admission:** Evaluate necessity, dependencies, maintenance, and native alternatives before accepting a plugin.
- **Stage-aware implementation:** Introduce features at their assigned roadmap stage.
- **Reproducibility:** Document requirements, dependencies, and architectural decisions.
- **Testability:** Validate each implementation and preserve regression coverage.
- **Replaceability:** Retire or replace plugins when evidence justifies the change.
- **Explicit activation:** Installing a shared plugin repository does not automatically enable every module it provides.
- **Direct loading:** Keep configuration module loading explicit in the root `init.lua`.
- **Behavior-based verification:** Distinguish successful registration and configuration checks from verified interactive behavior.

## Current status

The project follows a 17-stage roadmap. Stages 05, 06, 08, 09, and 11 have completed implementation and their defined automated validation. Stage 07's navigation and editing workflows have also been interactively tested.

**Stage 04 remains in progress** because native commenting is unresolved. **Stage 10's interactive verification remains in progress:** completion behavior has been tested, but snippet discovery and expansion, placeholder navigation, the complete automatic-pairing workflow, and related mapping regressions still require explicit verification.

Later stages may be developed and validated independently without treating unfinished earlier work as complete.

### Stage summary

| Stage | Scope | Status |
|---|---|---|
| 01 | First Init | Complete |
| 02 | Keymaps and Autocommands | Complete |
| 03 | Modules | Complete |
| 04 | Native Workflows | In progress — native commenting unresolved |
| 05 | Native Plugin Management and Colorscheme | Complete |
| 06 | Keymap Discovery and Icons | Complete |
| 07 | Navigation and Editing Workflows | Implementation validated; interactive checks reported passed |
| 08 | Tree-sitter | Complete |
| 09 | LSP and lazydev | Complete |
| 10 | Completion and Snippets | Interactive verification in progress |
| 11 | Manual Formatting | Complete |
| 12 | Git, Root, and Sessions | Planned |
| 13 | Language Packs | Planned |
| 14 | Debugging | Planned |
| 15 | UI Polish | Planned |
| 16 | Performance | Planned |
| 17 | Hardening | Planned |

Stage status reflects implementation and available validation evidence. A stage must satisfy its acceptance criteria before it is marked complete.

### Stage 04 — Native Workflows

Stage 04 prioritizes Neovim's built-in capabilities before introducing plugins. Its scope includes native search and quickfix integration, commenting, a built-in statusline, a diagnostics baseline, a terminal workflow, regression tests, and documentation.

Native commenting mappings are:

- `gcc` — toggle commenting on the current line.
- `gc` followed by a motion — toggle commenting over the motion.
- Visual selection followed by `gc` — toggle commenting on the selection.

Testing found that `gcc` worked in `nvim --clean` but left a line unchanged in the configured session. Visual-mode commenting also behaved unexpectedly, and the root cause has not been established. The terminal-mode Escape workflow has been interactively verified. Do not mark commenting functional based only on mapping registration or smoke-test assertions.

See [Native Keymap and Interactive Workflow Testing](docs/Keymap-test.md) for the testing procedure and diagnostic findings.

### Stage 07 — Navigation and Editing Workflows

The implemented workflow includes:

- **Snacks.nvim:** Picker and Explorer for file discovery, content search, buffer selection, and directory navigation.
- **fzf-lua:** An independent fuzzy-finding workflow with its own configuration and keymaps.
- **flash.nvim:** Enhanced motion and search navigation.
- **Selected `mini.nvim` modules:** `mini.ai`, `mini.surround`, and `mini.move`.
- **dial.nvim:** Increment and decrement operations for supported values and selections.
- **which-key.nvim:** Keymap discovery.

Snacks Picker and `fzf-lua` configuration and mappings remain independent. The Snacks dashboard is deferred to Stage 15. External navigation dependencies include `fd` and `fzf`; on Windows, their installation and verification are handled by `scripts/win-depend.ps1`.

The reported interactive checks passed. Plugins introduced before Stage 16 remain eagerly loaded; lazy-loading is not part of Stage 07.

### Stage 08 — Tree-sitter

Stage 08 installs `nvim-treesitter` through `vim.pack`, configures parser and query storage under Neovim's data directory, and enables native Tree-sitter highlighting for Lua buffers through `vim.treesitter.start()` and an explicit `FileType` autocommand.

On Windows, parser installation requires GNU tar, a compatible GCC/G++ toolchain, the Tree-sitter CLI (version 0.26.1 or later under the current setup policy), and cURL. The setup script changes `PATH` and `CC` for the current PowerShell process and its child processes; those changes are not persisted as Windows environment settings.

Tree-sitter highlighting does not automatically enable Tree-sitter indentation, folding, LSP, completion, formatting, or linting.

### Stage 09 — LSP and lazydev

Stage 09 integrates Neovim's native LSP client with LuaLS. It uses `nvim-lspconfig` and `lazydev.nvim`, while configuration and activation use Neovim's native `vim.lsp.config` and `vim.lsp.enable` APIs.

Shared attachment behavior lives in `lua/config/lsp.lua`; LuaLS settings live in `lua/langs/lua.lua`. The externally installed `lua-language-server` is used instead of Mason. LuaLS recognizes `vim` as a global, disables third-party workspace prompts, and disables telemetry.

Automated tests verify the configuration contract. Interactive testing confirmed LuaLS attachment, definition navigation, and hover. Declaration navigation did not work in the tested case; that result depends on the symbol and server response and does not prove all declaration requests fail. Diagnostics and non-LSP buffer isolation remain separate verification items.

### Stage 10 — Completion and Snippets

Stage 10 includes:

- **blink.cmp:** Completion engine installed through `vim.pack`.
- **friendly-snippets:** Snippet definitions.
- **Native `vim.snippet`:** Snippet expansion and navigation.
- **mini.pairs:** Automatic bracket and quote pairing, activated from the existing `mini.nvim` installation.

Blink's configured sources are LSP, filesystem paths, snippets, and words from the current buffer. The implementation uses Blink's Lua fuzzy-search implementation and default keymap preset; completion documentation is not shown automatically.

The project deliberately avoids LuaSnip, nvim-cmp, and Mason. All plugins continue to load eagerly; lazy-loading remains deferred to Stage 16. Automated validation and interactive completion candidate display, navigation, and acceptance have passed. Snippet discovery and expansion, placeholder navigation, complete automatic-pairing behavior, and related mapping regressions still need explicit interactive verification.

### Stage 11 — Manual Formatting

Stage 11 adds [Conform.nvim](https://github.com/stevearc/conform.nvim) as the Neovim-side formatting interface and StyLua as the Lua formatter. Conform is installed with `vim.pack`; the StyLua executable is managed separately.

The implementation:

- Declares formatter metadata in language packs and aggregates it through `require("langs").collect("formatters")`.
- Registers `:Format` and the `<leader>cf` mapping for manual formatting.
- Warns when a buffer has no configured formatter or the required formatter executable is unavailable.
- Disables LSP formatting explicitly.
- Does not configure format-on-save.
- Does not add a linter or Mason.

Validation passed on Neovim 0.12.6: StyLua formatting checks, Lua syntax checks across 27 files, the configured smoke test, formatter registration and command/keymap checks, manual StyLua formatting, missing-executable warning behavior, and checks confirming that formatting is not triggered on save.

Stage 11 is complete for its defined manual-formatting scope. Linting is not included in this stage.

## Repository structure

The main configuration and plugin modules are organized by responsibility:

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
│   ├── keymaps.md
│   ├── lsp.md
│   └── decisions/
├── lua/
│   ├── config/
│   │   ├── options.lua
│   │   ├── keymaps.lua
│   │   ├── autocmds.lua
│   │   ├── lsp.lua
│   │   └── format.lua
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
│       ├── mini-pairs.lua
│       └── conform.lua
└── scripts/
    ├── check-syntax.lua
    ├── smoke.lua
    ├── win-depend.ps1
    └── winsetup.ps1
```

This tree shows the main source layout; consult the current checkout for the full list of documentation and files.

## Validation

Run these commands from the repository root. The examples use PowerShell, matching the documented Windows setup.

### Check Lua syntax

```powershell
nvim --headless -u NONE -l scripts/check-syntax.lua
```

The checker compiles discovered Lua files without executing their contents. It exits with status `0` when all checked files compile successfully and a nonzero status when syntax errors are found.

### Run the smoke test

```powershell
nvim --headless -u init.lua -c "luafile scripts/smoke.lua"
```

The smoke test checks the Neovim version, representative options, leader keys, module loading, keymaps, autocommand registration, native search and quickfix behavior, the required-module failure contract, and the plugin/workflow assertions implemented in the test suite.

A passing smoke test does not establish that every workflow behaves correctly during interactive use. In particular, Stage 10 assertions do not replace interactive tests of snippet expansion, placeholder navigation, and pairing behavior.

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

### Verify Tree-sitter prerequisites

```powershell
gcc --version
g++ --version
tree-sitter --version
tar --version
$env:CC
```

Then open a Lua file in Neovim and inspect a syntax token with `:Inspect`. The Lua parser must be installed; external dependency checks alone do not prove parser installation and highlighting work.

### Verify LSP

```powershell
Get-Command lua-language-server
```

Open a Lua file and verify that LuaLS attaches. Test definition navigation, hover, diagnostics, and buffer-local mapping behavior as described in [Native Keymap and Interactive Workflow Testing](docs/Keymap-test.md). A registered LSP configuration does not prove that the server started or attached successfully.

### Check formatting

Install [StyLua](https://github.com/JohnnyMorganz/StyLua) separately, then run the repository formatting check:

```powershell
stylua --check .
```

To apply StyLua formatting to the repository:

```powershell
stylua .
```

Inside Neovim, use `:Format` or `<leader>cf` to manually format the current buffer when its language pack declares an available formatter.

### Check the Git diff

Before committing, review the working tree and staged changes:

```powershell
git status --short
git diff --check
git diff --cached --check
git diff --cached --stat
```

`git diff --check` checks unstaged tracked changes; `git diff --cached --check` checks staged changes. Neither includes untracked files until they are staged. Review new files and the complete staged diff before committing. Distinguish line-ending warnings from whitespace errors; `.gitattributes` defines repository line-ending behavior.

Run syntax, smoke, formatting, and diff checks after changes. Test new interactive workflows in a real Neovim session before marking their stage complete.

## Plugin policy

A plugin is not accepted merely because it is popular or appears in another Neovim distribution. Candidates are evaluated for:

- Necessity and native alternatives.
- Maintenance and compatibility.
- Dependencies and external executables.
- Architectural fit.
- Configuration complexity and replaceability.

Accepted plugins may be deferred to their assigned stage. Plugins may be retired or replaced when evidence justifies the change.

The project uses Neovim's native `vim.pack` for plugin management. Lazy-loading is deferred to Stage 16 and must be validated against the minimum supported Neovim version before adoption. Plugin installation, module activation, and feature configuration are explicit decisions.

## Contributing

Contributions should respect the architecture, roadmap, plugin admission policy, and testing requirements. Keep changes focused, document relevant decisions, run appropriate automated checks, and verify interactive behavior before marking a stage complete.

## License

This project is licensed under the [MIT License](LICENSE).

Copyright (c) 2025 HETFS LIMITED

