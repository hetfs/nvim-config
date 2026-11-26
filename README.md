# nvim-config

A native-first, modular Neovim configuration built incrementally around Neovim's built-in capabilities.

> **Minimum installation. Compose the rest.**

The project prioritizes minimal installation, explicit plugin evaluation, reproducible setup, and stage-by-stage validation. It uses Neovim's native plugin manager and APIs wherever practical, introducing external plugins only when they provide a clear architectural benefit.

## Table of Contents

- [Overview](#overview)
- [Requirements](#requirements)
- [Installation](#installation)
- [Language Support](#language-support)
- [Architecture and Design Principles](#architecture-and-design-principles)
- [Core Workflows](#core-workflows)
- [Roadmap and Project Status](#roadmap-and-project-status)
- [Validation](#validation)
- [Plugin Policy](#plugin-policy)
- [Documentation](#documentation)
- [Contributing](#contributing)
- [License](#license)

## Overview

`nvim-config` is a standalone Neovim configuration designed around a modular, native-first architecture.

Its primary objectives are:

- Minimize external dependencies.
- Prefer built-in Neovim functionality.
- Keep configuration modules focused and maintainable.
- Introduce plugins through explicit architectural evaluation.
- Separate Neovim plugins from external executables.
- Validate features through automated and interactive testing.
- Maintain clear implementation and acceptance criteria.

The configuration uses Neovim's native `vim.pack` for plugin management rather than traditional plugin managers such as `lazy.nvim`.

## Requirements

### Core requirements

- [Neovim](https://neovim.io/doc/install/) 0.12.0 or later.
- [Git](https://git-scm.com/).
- [fd](https://github.com/sharkdp/fd) for file and directory discovery.
- [fzf](https://github.com/junegunn/fzf) for the independent `fzf-lua` fuzzy-finding workflow.
- [ripgrep](https://github.com/BurntSushi/ripgrep) (`rg`) for content-search workflows.

### External tools

Additional executables depend on the language packs and workflows being used.

Examples include:

| Category | Dependencies |
|---|---|
| Data formats | YAML Language Server, JSON Language Server, Prettier, `jq`, and Taplo. `jq-lsp` is optional. |
| Lua | Lua Language Server and StyLua |
| Python | `ty` and Ruff |
| Tree-sitter | Tree-sitter CLI, GNU tar, cURL, and a compatible C compiler |
| Other languages | Language servers, formatters, linters, runtimes, and debuggers required by the corresponding language packs |

Neovim plugins do not automatically install these external executables. Manage them separately using the documented installation procedures.

### Windows dependencies

`scripts/win-depend.ps1` installs and verifies dependencies within its defined scope.

It also:

- Checks the Tree-sitter CLI.
- Configures the WinLibs GCC/G++ toolchain for the current PowerShell process.
- Verifies the dependencies covered by the script.

It does not install every external executable used by the configuration.

The data-language pack has a dedicated Windows installation entry point:

```powershell
.\scripts\install\windows\data-pack.ps1
```

This orchestrates the YAML, JSON, optional jq-lsp, and TOML installers. The `jq` executable is installed separately and checked by the orchestrator.

See [Dependencies](docs/dependencies.md) for installation policies, dependency details, and verification procedures.

## Installation

`nvim-config` requires **Neovim 0.12.0 or later** and remains under active development.

### Windows

Follow the [Windows installation guide](docs/win-install.md) for:

- Dependency installation.
- Configuration setup.
- Backup procedures.
- Optional settings.
- Installation verification.

### Linux and macOS

Installation and validation procedures for Linux and macOS have not yet been documented.

The Windows installation guide is not a cross-platform installation procedure.

## Language Support

Stage 13 organizes language-specific configuration into focused packs under `lua/langs/`.

Each pack contributes language metadata through the existing language registry.

The current implementation includes **18 language and tooling integrations**:

- 13 core language groups.
- 5 additional integrations.
- 4 future language candidates tracked separately.

### Core languages

The following languages form the core language baseline.

| Language | Classification |
|---|---|
| C | Core |
| HTML | Core |
| JavaScript/TypeScript | Core |
| JSON | Core |
| Lua | Core |
| Markdown | Core |
| PowerShell | Core |
| Python | Core |
| Rust | Core |
| Shell | Core |
| TOML | Core |
| YAML | Core |

**Note:** The current core-language count is 12 based on the listed integrations.

### Additional integrations

| Language or format | Classification |
|---|---|
| C++ | Additional |
| Docker | Additional |
| Go | Additional |
| MDX | Additional |
| SQL | Additional |

C++ remains separate from the core C language integration. MDX is also tracked separately from Markdown.

### Future language support

The following languages are candidates for future implementation:

- Java
- Kotlin
- Swift
- Zig

These candidates are not implemented integrations and are excluded from the Stage 13 completion count.

Each candidate requires an independent evaluation covering:

- Language-server support.
- Formatting and linting tools.
- Tree-sitter parser availability.
- External dependencies.
- Platform compatibility.
- Architectural fit.
- Validation requirements.

### Language pack architecture

Language packs reuse the existing Neovim configuration architecture. They do not introduce a separate language-server manager or install external tools during Neovim startup.

The implementation follows these principles:

- Use Neovim's native LSP APIs for configuration and activation.
- Keep language-specific settings and tooling metadata within their respective packs.
- Aggregate pack metadata through the existing language registry.
- Keep formatting and diagnostics as separate workflows.
- Manage external tools independently from Neovim plugins.
- Validate actual language-server attachment, diagnostics, formatting, parser behavior, and interactive workflows.

Stage 13 is complete for its defined scope. Future language candidates do not reopen or extend that acceptance.

### Language documentation

- [Data Language Pack](docs/data-pack.md)
- [JSON Support](docs/json-support.md)
- [jq Support](docs/jq-support.md)
- [Python Support](docs/python-support.md)
- [TOML Support](docs/toml-support.md)
- [YAML Support](docs/yaml-support.md)

## Architecture and Design Principles

The configuration follows a modular architecture that prioritizes native Neovim capabilities and explicit integration boundaries.

### Design principles

- **Native-first:** Prefer Neovim's built-in capabilities before introducing plugins.
- **Native plugin management:** Use Neovim's built-in `vim.pack`, not `lazy.nvim`.
- **Modularity:** Keep configuration modules focused and maintainable.
- **Explicit plugin admission:** Evaluate necessity, dependencies, maintenance, and native alternatives before accepting a plugin.
- **Stage-aware implementation:** Introduce features within their assigned roadmap stages.
- **Reproducibility:** Document requirements, dependencies, and architectural decisions.
- **Testability:** Validate implementations and maintain regression coverage.
- **Replaceability:** Retire or replace plugins when evidence justifies the change.
- **Explicit activation:** Installing a shared plugin repository does not automatically enable every module it provides.
- **Direct loading:** Keep configuration module loading explicit in the root `init.lua`.
- **External dependency separation:** Plugins do not automatically install the executables or language servers they use.
- **Explicit state changes:** Keep session operations deliberate and distinguish project root detection from automatic working-directory changes.
- **Behavior-based verification:** Distinguish successful registration and configuration checks from verified interactive behavior.

### Configuration architecture

The configuration uses focused modules and explicit integration boundaries.

Language-specific configuration lives under `lua/langs/`, while shared functionality remains within the existing configuration modules.

The architecture avoids introducing duplicate frameworks for functionality already provided by Neovim or existing project modules.

## Core Workflows

### Native LSP

The configuration uses Neovim's native:

- `vim.lsp.config()`
- `vim.lsp.enable()`

APIs for language-server configuration and activation.

Shared attachment behavior is maintained separately from language-specific server settings.

`nvim-lspconfig` and `lazydev.nvim` provide supporting integration where required. Language-server executables remain external dependencies.

### Completion and snippets

The completion workflow uses:

| Component | Responsibility |
|---|---|
| `blink.cmp` | Completion |
| `friendly-snippets` | Snippet definitions |
| `mini.pairs` | Automatic bracket and quote pairing |
| Native `vim.snippet` | Snippet expansion and placeholder navigation |

The configuration avoids LuaSnip, nvim-cmp, and Mason.

### Formatting

[Conform.nvim](https://github.com/stevearc/conform.nvim) provides the Neovim-side formatting interface.

Formatting is explicit and manual by default:

- `:Format` formats the current buffer.
- `<leader>cf` invokes the same workflow.
- Formatter metadata is declared by language packs.
- Missing formatter executables produce warnings.
- LSP formatting is explicitly disabled.
- Format-on-save is not configured.

### Git, projects, and sessions

| Component | Responsibility |
|---|---|
| Gitsigns | Git change indicators and hunk workflows |
| Lazygit | Optional external terminal application |
| `mini.sessions` | Explicit session save, restore, and delete operations |
| `project.nvim` | Project root detection and navigation |

Project root detection does not automatically change Neovim's working directory under the current configuration.

Session reads and writes are explicit rather than automatic.

## Roadmap and Project Status

The project follows a **31-stage roadmap**.

Implementation, validation, and formal stage acceptance are tracked separately. A feature being implemented or loading successfully does not automatically mean its stage is complete.

### Roadmap overview

| Stage | Scope | Status |
|---|---|---|
| 01–03 | Foundation and modular configuration | Complete |
| 04 | Native Workflows | In progress |
| 05–09 | Plugin management, discovery, navigation, Tree-sitter, and LSP | Complete |
| 10 | Completion and Snippets | Implementation complete; interactive verification outstanding |
| 11 | Manual Formatting | Complete |
| 12 | Git, Root, and Sessions | In progress; closeout outstanding |
| 13 | Language Packs | Complete |
| 14 | Debugging (DAP) | Planned |
| 15 | Development Workflows | Configuration complete; formal acceptance pending |
| 16 | Reserved | Scope undefined |
| 17–20 | Later roadmap stages | Implemented; behavioral/runtime acceptance outstanding |
| 21–22 | Later roadmap stages | Complete |
| 23–26 | Later roadmap stages | Implemented; behavioral/visual acceptance outstanding |
| 27–28 | Later roadmap stages | Complete |
| 29–31 | Later roadmap stages | Planned |

See [Roadmap](docs/roadmap.md) for complete stage definitions, dependencies, implementation progress, and acceptance criteria.

### Outstanding work

#### Stage 04 — Native Workflows

Native commenting remains unresolved.

Mapping registration and smoke-test assertions are not sufficient evidence that commenting works correctly in the configured session.

The root cause and interactive behavior must be resolved before the stage can close.

#### Stage 10 — Completion and Snippets

Implementation is complete.

Interactive verification remains outstanding for:

- Snippet discovery and expansion.
- Placeholder navigation.
- The complete automatic-pairing workflow.
- Related mapping regressions.

#### Stage 12 — Git, Root, and Sessions

Gitsigns, `project.nvim`, and `mini.sessions` are implemented.

Interactive Git workflows, project navigation, and session save/restore have passed validation. Stage 12 smoke tests also pass on Neovim 0.12.6.

Outstanding closeout requirements include:

- Documentation updates.
- Dependency references.
- Keymap references.
- Remaining stage acceptance requirements.
- Investigation of a headless `project.nvim` history-write warning observed during exit.

#### Stage 15 — Development Workflows

The CodeCompanion configuration work is complete.

Formal acceptance remains pending, including validation of the configured provider and relevant development workflows.

### Stage acceptance policy

Later stages can be implemented and validated independently. Their progress does not satisfy unfinished requirements in earlier stages.

A stage should only be marked complete when its defined requirements and acceptance criteria have been satisfied.

## Validation

Run validation commands from the repository root.

The examples below use PowerShell, matching the documented Windows setup.

### Check Lua syntax

```powershell
nvim --headless -u NONE -l scripts/check-syntax.lua
```

The checker compiles discovered Lua files without executing their contents.

It exits with status `0` when all checked files compile successfully and a nonzero status when syntax errors are found.

### Run Lua lint

LuaCheck is optional. If installed, run the repository-wide check:

```powershell
$LuaFiles = Get-ChildItem -Path . -Recurse -Filter "*.lua" -File |
    Where-Object {
        $_.FullName -notmatch '[\\/](\.git|node_modules|vendor|build|dist)[\\/]'
    } |
    ForEach-Object {
        $_.FullName
    }

luacheck `
    --no-config `
    --std luajit `
    --globals vim Snacks `
    --no-color `
    $LuaFiles
```

This uses the LuaJIT standard because Neovim embeds LuaJIT.

LuaCheck is a standalone repository check, not a Neovim startup dependency or diagnostics integration.

### Run the smoke test

```powershell
nvim --headless -u init.lua -c "luafile scripts/smoke.lua"
```

The smoke test checks:

- Neovim version.
- Representative options.
- Leader keys.
- Module loading.
- Keymaps.
- Autocommand registration.
- Configuration and workflow assertions implemented in the test suite.

A passing smoke test does not establish that every workflow behaves correctly during interactive use. Test interactive behavior separately before accepting a stage.

**Important:** Use the `-c "luafile scripts/smoke.lua"` invocation shown above. Do not substitute `-l scripts/smoke.lua` for this smoke-test command. Startup behavior differs and can produce misleading option-check failures.

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

Then open a supported file in Neovim and inspect a syntax token with:

```vim
:Inspect
```

External dependency checks alone do not prove that a parser is installed or highlighting works.

### Verify LSP

For LuaLS:

```powershell
Get-Command lua-language-server
```

Open a Lua file and verify that LuaLS attaches.

Test:

- Definition navigation.
- Hover.
- Diagnostics.
- Buffer-local mapping behavior.

A registered LSP configuration does not prove that the server started or attached successfully.

### Verify data-pack executables

After running the Windows data-pack installer, execute:

```vim
:lua print(vim.fn.executable("yaml-language-server"))
:lua print(vim.fn.executable("vscode-json-language-server"))
:lua print(vim.fn.executable("jq-lsp"))
:lua print(vim.fn.executable("taplo"))
:lua print(vim.fn.executable("prettier"))
:lua print(vim.fn.executable("jq"))
```

Each command should return `1` when the executable is available through Neovim's `PATH`.

A return value of `0` means Neovim cannot find it.

This verifies executable discovery only. Language-server attachment and feature behavior must be tested separately.

### Check formatting

Install [StyLua](https://github.com/JohnnyMorganz/StyLua) separately.

Check formatting:

```powershell
stylua --check .
```

Apply formatting:

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

`git diff --check` checks unstaged tracked changes.

`git diff --cached --check` checks staged changes.

Neither includes untracked files until they are staged. Review new files and the complete staged diff before committing.

### Validation expectations

Run syntax, smoke, formatting, and diff checks after changes.

Test new interactive workflows in a real Neovim session before marking their corresponding roadmap stages complete.

## Plugin Policy

A plugin is not accepted merely because it is popular or appears in another Neovim distribution.

Candidates are evaluated against the following criteria:

- Architectural fit.
- Configuration complexity and replaceability.
- Dependencies and external executables.
- Maintenance and compatibility.
- Necessity and availability of native alternatives.

Accepted plugins may be deferred to their assigned roadmap stages.

Plugins may also be retired or replaced when evidence justifies the change.

The project uses Neovim's native `vim.pack` for plugin management.

Plugin installation, module activation, and feature configuration are explicit decisions.

Lazy-loading is deferred to its assigned roadmap stage and must be validated against the minimum supported Neovim version before adoption.

## Documentation

| Document | Purpose |
|---|---|
| [Architecture](docs/architecture.md) | Configuration architecture and design boundaries |
| [Dependencies](docs/dependencies.md) | External dependency policy and setup |
| [Keymaps](docs/keymaps.md) | Keymap reference |
| [Plugin Admission Policy](docs/plugin-admission-policy.md) | Plugin evaluation and acceptance |
| [Plugin Inventory](docs/plugin-inventory.md) | Plugin inventory |
| [Roadmap](docs/roadmap.md) | Stage definitions, progress, and acceptance criteria |
| [Native Workflow Testing](docs/Keymap-test.md) | Interactive workflow testing and diagnostics |
| [Windows Installation](docs/win-install.md) | Windows setup and installation |

Additional language-specific documentation is available in the [Language Support](#language-support) section.

## Contributing

Contributions should respect the project's architecture, roadmap, plugin admission policy, and testing requirements.

When contributing:

- Keep changes focused.
- Document relevant architectural decisions.
- Follow existing module boundaries.
- Evaluate native alternatives before introducing plugins.
- Run appropriate automated checks.
- Verify interactive behavior before marking a stage complete.
- Preserve the distinction between implementation, configuration loading, and behavioral acceptance.

Do not treat implementation, successful module loading, or mapping registration as proof of behavioral acceptance.

## License

This project is licensed under the [MIT License](LICENSE).

Copyright (c) 2025 HETFS LIMITED
