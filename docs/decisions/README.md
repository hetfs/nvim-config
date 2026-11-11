# nvim-config

A native-first, modular Neovim configuration built incrementally around Neovim's built-in capabilities.

> **Minimum installation. Compose the rest.**

The project prioritizes a minimal installation, explicit plugin admission, reproducible setup, and stage-by-stage validation.

## Requirements

### Core requirements

- [Neovim](https://neovim.io/doc/install/) 0.12.0 or later.
- [Git](https://git-scm.com/).
- [ripgrep](https://github.com/BurntSushi/ripgrep) (`rg`) for content search.
- [fd](https://github.com/sharkdp/fd) for file and directory discovery.
- [fzf](https://github.com/junegunn/fzf) for the independent `fzf-lua` fuzzy-finding workflow.

### Additional requirements

Requirements depend on the enabled features and language packs.

| Component     | Requirements                                                                         |
| ------------- | ------------------------------------------------------------------------------------ |
| Tree-sitter   | Tree-sitter CLI, GNU tar, cURL, and a compatible C compiler.                         |
| LSP           | External language-server executables for the enabled language packs.                 |
| Formatting    | StyLua, Ruff, Prettier, and other formatters required by the enabled language packs. |
| Linting       | External linters required by the enabled language packs.                             |
| Git interface | [Lazygit](https://github.com/jesseduffield/lazygit), optional.                       |

Conform provides the Neovim-side formatting interface. It does not install formatter executables. Language servers, formatters, linters, and other external tools are managed separately from Neovim plugins.

### Windows dependencies

On Windows, `scripts/win-depend.ps1` uses WinGet to install and verify dependencies within its defined scope. It checks the Tree-sitter CLI and configures the WinLibs GCC/G++ toolchain for the current PowerShell process.

The script does not install every external tool used by the configuration. LuaLS and optional Lazygit are managed separately.

The data-language pack has a dedicated installation entry point:

```powershell
.\scripts\install\windows\data-pack.ps1
```

It orchestrates the individual YAML, JSON, jq-lsp, and TOML installers. The `jq` executable is installed separately and checked by the data-pack installer.

See [Dependencies](docs/architecture/dependencies.md) for dependency policy, installation responsibilities, and verification details.

## Installation

`nvim-config` requires **Neovim 0.12.0 or later** and remains under active development.

### Windows

Windows is the currently documented installation platform.

Follow the [Windows installation guide](docs/win-install.md) for dependency setup, configuration installation, backups, and optional settings.

### Linux and macOS

Installation and validation instructions for Linux and macOS have not yet been documented. The Windows guide is not a cross-platform installation procedure.

### Manual installation

To install the configuration manually:

1. Ensure that the required Neovim version and external dependencies are available.
2. Clone the repository into your Neovim configuration directory.
3. Review the dependency and platform-specific documentation.
4. Start Neovim and run the available health checks.

See [Dependencies](docs/architecture/dependencies.md) for the separation between system packages, external tools, and Neovim plugins.

## Design principles

- **Native-first:** Prefer Neovim's built-in capabilities before introducing plugins.
- **Native plugin management:** Use Neovim's built-in `vim.pack` instead of `lazy.nvim`.
- **Modularity:** Keep configuration modules focused and maintainable.
- **Explicit plugin admission:** Evaluate necessity, dependencies, maintenance, and native alternatives before accepting a plugin.
- **Stage-aware implementation:** Introduce features at their assigned roadmap stage.
- **Reproducibility:** Document requirements, dependencies, and architectural decisions.
- **Testability:** Validate implementations and maintain regression coverage.
- **Replaceability:** Retire or replace plugins when evidence justifies the change.
- **Explicit activation:** Installing a shared plugin repository does not automatically enable every module it provides.
- **Direct loading:** Keep configuration module loading explicit in the root `init.lua`.
- **Dependency separation:** Plugins do not automatically install the external executables or language servers they require.
- **Explicit state changes:** Keep session operations deliberate and distinguish project root detection from automatic working-directory changes.
- **Behavior-based verification:** Distinguish successful registration and configuration checks from verified interactive behavior.

## Roadmap

The project follows a 17-stage development roadmap. Each stage has defined implementation requirements and acceptance criteria.

### Current status

- **Stages 01–03:** Complete.
- **Stage 04 — Native Workflows:** In progress. The native commenting workflow remains unresolved.
- **Stages 05–09:** Complete. Stage 09's native LSP and lazydev implementation and defined validation are closed out.
- **Stage 10 — Completion and Snippets:** Implementation is in place. Interactive verification of snippet discovery and expansion, placeholder navigation, automatic pairing, and related mapping behavior remains outstanding.
- **Stage 11 — Format and Lint:** Complete for the defined manual formatting implementation and automated validation. Python's Ruff native LSP lint integration has also been implemented and validated within its Stage 13 language pack.
- **Stage 12 — Git, Root, and Sessions:** In progress. Gitsigns, `DrKJeff16/project.nvim`, and `mini.sessions` are implemented. Interactive checks for Git workflows, project navigation, and session save/restore have passed. Stage 12 smoke-test checks pass on Neovim 0.12.6. Documentation alignment, dependency and keymap updates, and remaining closeout requirements are outstanding.
- **Stage 13 — Language Packs:** In progress. All 11 baseline language packs have been implemented and validated except Markdown, which remains under implementation and validation. Markdown is the only outstanding baseline language pack.
- **Stages 14–17:** Planned.

Later-stage work must not imply that an earlier stage's outstanding requirements have been resolved. Stage 12 does not reopen Stage 09. Stage 13's completed language packs do not close Stage 10 or change the completion status of Stage 11.

> Update this status whenever a stage formally changes. Do not infer completion from the presence of configuration files alone.

### Stage summary

| Stage | Scope                                    | Status                                                                           |
| ----- | ---------------------------------------- | -------------------------------------------------------------------------------- |
| 01    | First Init                               | Complete                                                                         |
| 02    | Keymaps and Autocommands                 | Complete                                                                         |
| 03    | Modules                                  | Complete                                                                         |
| 04    | Native Workflows                         | In progress — native commenting unresolved                                       |
| 05    | Native Plugin Management and Colorscheme | Complete                                                                         |
| 06    | Keymap Discovery and Icons               | Complete                                                                         |
| 07    | Navigation and Editing Workflows         | Interactive checks reported passed                                               |
| 08    | Tree-sitter                              | Complete                                                                         |
| 09    | LSP and lazydev                          | Complete                                                                         |
| 10    | Completion and Snippets                  | Interactive verification in progress                                             |
| 11    | Manual Formatting                        | Complete                                                                         |
| 12    | Git, Root, and Sessions                  | In progress — implementation and initial validation passed; closeout outstanding |
| 13    | Language Packs                           | In progress — all baseline packs validated except Markdown                       |
| 14    | Debugging                                | Planned                                                                          |
| 15    | UI Polish                                | Planned                                                                          |
| 16    | Performance                              | Planned                                                                          |
| 17    | Hardening                                | Planned                                                                          |

A stage is complete only after its defined acceptance criteria have been satisfied.

## Stage 04 — Native Workflows

Stage 04 prioritizes Neovim's built-in capabilities before introducing plugins.

Its scope includes:

- Native search and quickfix integration.
- Commenting workflows.
- A built-in statusline.
- A diagnostics baseline.
- Terminal integration.
- Regression tests and documentation.

### Native commenting

The intended mappings are:

| Mapping                           | Behavior                               |
| --------------------------------- | -------------------------------------- |
| `gcc`                             | Toggle commenting on the current line. |
| `gc` followed by a motion         | Toggle commenting over the motion.     |
| Visual selection followed by `gc` | Toggle commenting on the selection.    |

Testing found that `gcc` worked in `nvim --clean` but left a line unchanged in the configured session. Visual-mode commenting also behaved unexpectedly. The root cause remains unresolved.

The terminal-mode Escape workflow has been interactively verified.

Do not mark commenting functional based only on mapping registration or smoke-test assertions.

See the native keymap and interactive workflow testing documentation for the testing procedure and diagnostic findings.

## Stage 07 — Navigation and Editing Workflows

The implemented workflow includes:

- **Snacks.nvim:** Picker and Explorer for file discovery, content search, buffer selection, and directory navigation.
- **fzf-lua:** An independent fuzzy-finding workflow with separate configuration and keymaps.
- **flash.nvim:** Enhanced motion and search navigation.
- **Selected `mini.nvim` modules:** `mini.ai`, `mini.surround`, and `mini.move`.
- **dial.nvim:** Increment and decrement operations for supported values and selections.
- **which-key.nvim:** Keymap discovery.

Snacks Picker and `fzf-lua` remain independent. The Snacks dashboard is deferred to Stage 15.

External navigation dependencies include `fd`, `fzf`, and `rg` for the workflows that use them.

Interactive checks have passed. Plugins introduced before Stage 16 remain eagerly loaded. Lazy-loading is not part of Stage 07.

## Stage 08 — Tree-sitter

Stage 08 installs `nvim-treesitter` through `vim.pack`, configures parser and query storage under Neovim's data directory, and enables native Tree-sitter highlighting through `vim.treesitter.start()` and an explicit `FileType` autocommand.

On Windows, parser-related workflows require:

- GNU tar.
- A compatible GCC/G++ toolchain.
- Tree-sitter CLI 0.26.1 or later under the current setup policy.
- cURL.

Tree-sitter highlighting does not automatically enable indentation, folding, LSP, completion, formatting, or linting.

## Stage 09 — LSP and lazydev

Stage 09 integrates Neovim's native LSP client with LuaLS.

It uses `nvim-lspconfig` and `lazydev.nvim` while configuration and activation use Neovim's native `vim.lsp.config()` and `vim.lsp.enable()` APIs.

Shared attachment behavior lives in `lua/config/lsp.lua`. LuaLS settings live in `lua/langs/lua.lua`.

The externally installed `lua-language-server` is used instead of Mason. LuaLS recognizes `vim` as a global, disables third-party workspace prompts, and disables telemetry.

Automated tests verify the configuration contract. Interactive testing confirmed LuaLS attachment, definition navigation, and hover. Declaration navigation did not work in the tested case. This result depends on the symbol and server response and does not establish that all declaration requests fail.

The LSP configuration does not imply that the language-server executable is installed by the Neovim plugin manager.

## Stage 10 — Completion and Snippets

Stage 10 includes:

- **blink.cmp:** Completion engine installed through `vim.pack`.
- **friendly-snippets:** Snippet definitions.
- **Native `vim.snippet`:** Snippet expansion and navigation.
- **mini.pairs:** Automatic bracket and quote pairing, activated from the existing `mini.nvim` installation.

Blink's configured sources are LSP, filesystem paths, snippets, and words from the current buffer. The implementation uses Blink's Lua fuzzy-search implementation and default keymap preset.

The project deliberately avoids LuaSnip, nvim-cmp, and Mason.

All plugins continue to load eagerly. Lazy-loading remains deferred to Stage 16.

Automated validation and interactive completion candidate display, navigation, and acceptance have passed. The following workflows still require explicit interactive verification:

- Snippet discovery and expansion.
- Placeholder navigation.
- Complete automatic-pairing behavior.
- Related mapping regressions.

## Stage 11 — Manual Formatting

Stage 11 adds [Conform.nvim](https://github.com/stevearc/conform.nvim) as the Neovim-side formatting interface and StyLua as the Lua formatter.

Conform is installed through `vim.pack`. The StyLua executable is managed separately.

The implementation:

- Declares formatter metadata in language packs.
- Aggregates formatter definitions through `require("langs").collect("formatters")`.
- Registers `:Format` and the `<leader>cf` mapping for manual formatting.
- Warns when a buffer has no configured formatter or the required executable is unavailable.
- Disables LSP formatting explicitly.
- Does not configure format-on-save.
- Does not introduce Mason.

Validation passed on Neovim 0.12.6. It covered StyLua formatting, Lua syntax, formatter registration, command and keymap registration, manual formatting, missing-executable warnings, and checks confirming that formatting does not run on save.

Stage 11 is complete for its defined manual-formatting scope. Language-specific linting is handled separately.

## Stage 12 — Git, Root, and Sessions

Stage 12 adds Git integration, project root detection and navigation, and explicit session management.

### Git integration

**Gitsigns** provides Git change indicators and hunk workflows, including stage, reset, preview, blame, and diff actions.

Git remains an external dependency. Gitsigns does not install it.

### Project management

**`DrKJeff16/project.nvim`** provides project root detection and project navigation.

Root detection does not automatically change Neovim's working directory under the current configuration.

### Session management

**`mini.sessions`** provides explicit session save, restore, and delete operations through the existing shared `mini.nvim` installation.

Automatic session reads and writes are disabled.

### Optional Git interface

**Lazygit** is an optional external terminal application. It is not a Neovim plugin or a core dependency.

### Validation and closeout

User-facing mappings remain centralized in `lua/config/keymaps.lua`. Gitsigns mappings are buffer-local. Session mappings invoke explicit operations, and the existing fzf-lua `<leader>pr` resume mapping remains independent of project navigation.

Interactive checks for Git workflows, project navigation, and session save/restore have passed. Stage 12 smoke-test checks also pass on Neovim 0.12.6.

The stage remains in progress until documentation, dependency and keymap references, automated checks, and remaining closeout requirements are reconciled.

A headless `project.nvim` history-write warning has also been observed during exit. It must be investigated before closeout.

## Stage 13 — Language Packs

Stage 13 organizes language-specific configuration into focused packs under `lua/langs/`.

Each pack contributes filetype, formatter, parser, and language-server metadata through the existing language registry.

### Language baseline

The Stage 13 baseline covers these 11 language groups in the agreed implementation order:

1. Lua
2. Python
3. YAML
4. JSON
5. Shell
6. PowerShell
7. HTML
8. CSS
9. JavaScript/TypeScript
10. Markdown
11. Rust

This is the agreed build order. It determines the sequence of implementation and validation, not merely the order in which languages appear in documentation.

### Current implementation status

| Language group        | Classification | Status      |
| --------------------- | -------------- | ----------- |
| Lua                   | Core           | Complete    |
| Python                | Core           | Complete    |
| YAML                  | Core           | Complete    |
| JSON                  | Core           | Complete    |
| Shell                 | Core           | Complete    |
| PowerShell            | Core           | Complete    |
| HTML                  | Core           | Complete    |
| CSS                   | Core           | Complete    |
| JavaScript/TypeScript | Core           | Complete    |
| Markdown              | Core           | In progress |
| Rust                  | Core           | Complete    |

HTML and CSS are part of the core baseline. They must not be classified as optional language packs because earlier documentation placed HTML under an optional web pack.

Optional language packs remain separate from the 11-language core baseline. Their inclusion requires an explicit decision and must not change the agreed core build order.

### Completed language packs

All baseline packs except Markdown have completed their defined implementation and validation.

#### Lua

- LuaLS through native Neovim LSP configuration.
- Approved LuaLS runtime and diagnostic settings.
- StyLua formatting through Conform.
- Tree-sitter parsing and highlighting.

#### Python

- `uv` for Python project and environment management.
- `ty` for language-server functionality and type diagnostics.
- Ruff CLI for standalone linting.
- Ruff native LSP for editor diagnostics.
- Conform with `ruff_format` for formatting.
- Tree-sitter parsing and highlighting.

Ty and Ruff operate as separate LSP clients. Ruff's editor integration is diagnostic-focused; formatting remains the responsibility of Conform.

Python validation confirmed that both clients attach together and continue to attach after a fresh Neovim start.

Language-specific lint integration does not imply that every baseline language has the same linting capabilities.

### Remaining baseline work: Markdown

Markdown is the only outstanding baseline language pack.

The implementation and validation work covers:

- Marksman through native Neovim LSP configuration.
- Prettier formatting through Conform.
- Tree-sitter Markdown and Markdown Inline parsers.
- `delphinus/md-render.nvim` as the selected default baseline preview candidate.
- `sammaji/markdown-preview.nvim` as an optional browser-preview extension.
- Independent configuration and validation for each preview implementation.
- Explicit external dependency requirements and installation documentation.
- Automated and interactive validation on the supported environment.

Neither preview implementation should open or render automatically. Users must activate previews explicitly.

The default preview candidate must pass compatibility validation on Windows with WezTerm before its baseline admission is considered complete.

Markdown linting with `markdownlint-cli2` remains a separate evaluation and admission decision. It must not be described as an established baseline capability until its configuration, dependencies, and validation requirements are confirmed.

### Additional language integrations

Additional integrations are maintained separately from the 11-language baseline. These include:

- C.
- C++.
- Docker.
- SQL.

Their implementation does not change the baseline language count or the agreed implementation order. Their status and dependencies should be documented independently.

### Scope

- Maintain the agreed 11-language baseline.
- Keep language-specific configuration modular.
- Reuse the established native LSP registry and activation architecture from Stage 09.
- Use Conform for approved formatting workflows.
- Keep language-server, formatter, linter, parser, and schema responsibilities explicit.
- Document external dependencies and installation requirements.
- Keep external executable installation and updates separate from Neovim plugin installation.
- Validate each language independently.
- Keep optional integrations separate from the baseline.

### Completion criteria

- Every baseline language has a documented dependency set.
- Each language pack has a clearly defined configuration and responsibility boundary.
- Language-server configuration uses the established native LSP architecture.
- Formatting and linting responsibilities are explicit and do not conflict.
- Required external tools are documented and available in the validation environment.
- Parser, language-server, diagnostic, formatting, linting, and preview workflows are validated where applicable.
- Language-specific configuration passes syntax and formatting checks.
- The language index and supporting documentation reflect the actual implementation.
- The configuration avoids installing unrelated tools by default.
- Each language is marked complete only after its own implementation and required validation are finished.

### Implementation boundaries

- Stage 13 does not reopen Stage 09's completed LSP foundation.
- Stage 13 does not reopen Stage 10's completion and snippet implementation.
- Language-specific lint integration may be implemented and validated within its language pack without implying that every language has lint support.
- Formatting remains manual by default. Do not introduce format-on-save or LSP formatting fallback without a separate decision.
- Do not introduce Mason or Neovim-side external-tool installation.
- Do not mark the entire stage complete while Markdown remains outstanding.

Stage 13 remains in progress. The other 10 baseline language groups are complete; Markdown is the only remaining baseline pack.

## Repository structure

The configuration uses a modular layout. Core Neovim settings, language integrations, plugin configuration, documentation, and installation scripts have separate responsibilities.

```text
nvim-config/
├── init.lua
├── nvim-pack-lock.json
├── docs/
│   ├── architecture/
│   ├── decisions/
│   └── ...
├── lua/
│   ├── config/
│   ├── langs/
│   ├── lsp/
│   └── plugins/
└── scripts/
    ├── install/
    │   └── windows/
    ├── check-syntax.lua
    ├── smoke.lua
    ├── doctor.lua
    └── ...
```

### Directory responsibilities

| Path                 | Responsibility                                                        |
| -------------------- | --------------------------------------------------------------------- |
| `init.lua`           | Loads configuration modules directly.                                 |
| `lua/config/`        | Core Neovim options, keymaps, autocommands, and shared configuration. |
| `lua/langs/`         | Language-pack definitions and language-specific tooling metadata.     |
| `lua/lsp/`           | Language-server configuration and shared LSP behavior.                |
| `lua/plugins/`       | Explicit plugin declarations and setup.                               |
| `docs/architecture/` | Architecture, dependency, and design documentation.                   |
| `docs/decisions/`    | Recorded architectural and implementation decisions.                  |
| `scripts/`           | Smoke tests, diagnostics, and supporting maintenance tasks.           |
| `scripts/install/`   | Explicit external dependency installation workflows.                  |

This tree shows the main source layout, not every file. Individual modules and scripts may change as the roadmap progresses.

## Testing and Validation

The configuration uses layered validation to catch syntax errors, configuration regressions, and workflow failures.

A stage is complete only when its defined implementation and acceptance criteria have passed. The presence of configuration files or a successful startup alone does not establish completion.

### Validation layers

| Layer                | Purpose                                                                                            |
| -------------------- | -------------------------------------------------------------------------------------------------- |
| Syntax checks        | Detect Lua syntax errors in configuration and supporting scripts.                                  |
| Formatting checks    | Verify that project Lua files follow the configured StyLua rules.                                  |
| Headless smoke tests | Validate configuration loading and supported behavior without an interactive UI.                   |
| Interactive tests    | Verify workflows that depend on user input, buffers, windows, terminals, or external applications. |
| Health checks        | Inspect configuration health and report missing or incompatible dependencies.                      |
| Stage acceptance     | Confirm that all requirements and outstanding issues for a stage have been addressed.              |

### Automated checks

Run the checks available in the repository from its root directory.

Check Lua syntax:

```powershell
nvim --headless -u NONE -l scripts/check-syntax.lua
```

Check formatting:

```powershell
stylua --check .
```

Run the configuration smoke tests:

```powershell
nvim --headless -u init.lua -l scripts/smoke.lua
```

The smoke-test runner supports suite selection and exclusion through its documented environment variables:

- `SMOKE_ONLY` selects specific suites.
- `SMOKE_SKIP` excludes selected suites.
- `SMOKE_LIST` lists available suites.

Consult the runner's implementation and documentation for accepted values and invocation details.

A passing automated check does not replace interactive verification for workflows that require a UI or external application. Report the overall smoke-test result separately from individual stage checks.

### Interactive validation

Some workflows require a real Neovim session. These include:

- Keymap behavior and mode-specific interactions.
- Native commenting and editing workflows.
- Completion menus, snippet expansion, and placeholder navigation.
- Automatic pairing and selection behavior.
- Git operations and Gitsigns interactions.
- Project-root detection and project navigation.
- Session creation, restoration, and recovery.
- Language-server attachment and diagnostics.
- Formatting, linting, and preview workflows.

Validate these behaviors in the supported environment. Do not infer interactive success from headless tests.

### Environment validation

The primary validated development environment is Windows with Neovim 0.12.6.

Check external dependencies independently of plugin installation. Use the project's health checks and platform-specific dependency documentation to identify missing tools and configuration problems.

### Reporting results

Record validation results against the relevant roadmap stage.

- Mark a check as passed only after successful execution.
- Keep interactive and automated results distinct.
- Record unresolved failures and known limitations.
- Do not treat a later-stage test as evidence that an earlier stage has passed.
- Re-run affected checks after changing shared configuration, plugin setup, or language-pack behavior.

Stage completion requires evidence for its defined acceptance criteria, not simply a successful Neovim startup.

## Plugin policy

A plugin is not accepted merely because it is popular or appears in another Neovim distribution.

Evaluate candidates against the following criteria:

- Necessity and availability of native alternatives.
- Maintenance and compatibility.
- Dependencies and external executables.
- Architectural fit.
- Configuration complexity and replaceability.

Accepted plugins may be deferred to their assigned stage. Retire or replace plugins when evidence justifies the change.

The project uses Neovim's native `vim.pack` for plugin management. Lazy-loading is deferred to Stage 16 and must be validated against the minimum supported Neovim version before adoption.

Plugin installation, module activation, and feature configuration are separate, explicit decisions.

## Contributing

Contributions should respect the architecture, roadmap, plugin admission policy, and testing requirements.

Keep changes focused, document relevant decisions, run the appropriate automated checks, and verify interactive behavior before marking a stage complete.

## License

This project is licensed under the [MIT License](LICENSE).

Copyright (c) 2025 HETFS LIMITED
