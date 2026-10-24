# Plugin Inventory

## Purpose

This document records the plugin choices, implementation stages, and admission boundaries for `nvim-config`.

The project follows a native-first approach: Neovim's built-in capabilities take priority, and external plugins are added only when they provide a justified benefit.

> **Approval is not installation.**

A plugin listed in this inventory is not automatically approved for installation. Its presence in a stage plan records an intended evaluation or implementation, not proof that it is installed, configured, or validated.

## Plugin Admission Policy

Before a plugin is admitted, evaluate:

- **Purpose:** What concrete capability does it provide?
- **Native alternative:** Can Neovim already provide the required behavior?
- **Overlap:** Does it duplicate an existing plugin or workflow?
- **Dependencies:** Does it require external executables, libraries, parsers, or adapters?
- **Maintenance:** Is the project maintained and appropriate for this configuration?
- **Stage fit:** Does it belong to the active roadmap stage?
- **Validation:** How will its behavior be tested?
- **Removal cost:** Can it be removed without destabilizing unrelated configuration?

A plugin should be installed only after its role and stage have been explicitly accepted.

## Inventory Status Definitions

| Status | Meaning |
|---|---|
| Implemented | Configuration is present in the repository; runtime behavior must still be validated separately |
| Planned | Assigned to a future or active roadmap stage but not confirmed as installed |
| Deferred | Deliberately postponed pending a later stage or a documented decision |
| Candidate | Under consideration; not approved for installation |
| Rejected | Evaluated and not selected for the current architecture |

Do not use *Implemented* as a synonym for *Fully validated* or *Stage complete*.

## Core Policy

### Native Neovim capabilities

Prefer built-in functionality for:

- Options, mappings, and autocommands.
- Window and buffer management where the native workflow is sufficient.
- Native commenting mappings.
- Built-in LSP configuration and activation APIs.
- Plugin management through `vim.pack`.
- Native Lua configuration and runtime facilities.

Native functionality should not be duplicated by a plugin without a documented reason.

### Plugin management

The project uses Neovim's built-in `vim.pack` plugin manager.

- Do not introduce `lazy.nvim` as the plugin manager.
- Keep plugin setup explicit.
- Avoid duplicate installations of shared repositories.
- Keep plugin loading eager through Stage 15.
- Evaluate lazy-loading in Stage 16 only when measurements and compatibility testing justify it.

### External tools

External executables are managed separately from Neovim plugins.

Examples include language servers, formatters, linters, debuggers, compiler toolchains, and Git utilities. Their installation requirements should be documented in `docs/dependencies.md` and relevant platform setup instructions.

The project does not adopt Mason as its default external-tool installation mechanism.

## Stage-Based Inventory

The following inventory records the project's established selections and roadmap direction. Confirm actual installation and configuration against the repository before treating any item as fully implemented.

### Stage 05 — Plugin Management and Colorscheme

| Plugin or tool | Intended role | Policy |
|---|---|---|
| Catppuccin | Colorscheme | Selected for the base UI |
| `vim.pack` | Native plugin management | Required; built into supported Neovim versions |

Catppuccin is configured through the plugin configuration layer. Plugin management remains native and does not depend on `lazy.nvim`.

### Stage 06 — Mapping Discovery and Icons

| Plugin | Intended role | Policy |
|---|---|---|
| which-key.nvim | Discover mappings and leader-key groups | Selected |
| mini.icons | Icon support for integrations | Selected |
| mini.nvim | Shared repository for Mini modules | Install once when the first Mini module is admitted |

`mini.nvim` is a shared repository. Individual Mini modules should be configured independently without adding duplicate repository installations.

### Stage 07 — Navigation and Editing

| Plugin | Intended role | Policy |
|---|---|---|
| folke/snacks.nvim | Navigation, picker facilities, and selected UI utilities | Selected; shared setup path |
| fzf-lua | Fuzzy finding and navigation | Selected; independent from Snacks Picker |
| flash.nvim | Fast motion and search navigation | Selected |
| mini.ai | Text objects | Selected Mini module |
| mini.move | Move selected text and lines | Selected Mini module |
| mini.surround | Surround editing | Selected Mini module |
| mini.pairs | Automatic paired-character behavior | Roadmap candidate; confirm admission and stage assignment |
| mini.hipatterns | Highlight configured text patterns | Roadmap candidate; confirm admission and stage assignment |

**Independence requirement:** Snacks Picker and fzf-lua must retain separate configuration and mapping decisions. Neither should silently replace the other.

**Shared setup requirement:** Snacks should have one shared setup path. Feature-specific configuration, such as the later dashboard module, may be separated without duplicating the core setup.

The exact admission and closeout status of every Stage 07 item should be verified against the repository before updating these entries to *Implemented*.

### Stage 08 — Treesitter

| Plugin or dependency | Intended role | Policy |
|---|---|---|
| nvim-treesitter | Tree-sitter-based syntax parsing and highlighting | Selected |
| Compiler toolchain | Build parsers where required | External dependency; document per platform |
| Tree-sitter parsers | Language-specific syntax parsing | Configure deliberately; validate availability and compatibility |

The plugin and its parsers are separate concerns. Installing the plugin alone does not prove that every parser is installed, compiled, or working.

### Stage 09 — LSP and Lua Development

| Plugin or capability | Intended role | Policy |
|---|---|---|
| Native Neovim LSP APIs | Configure and enable language servers | Preferred foundation |
| lazydev.nvim | Lua development support | Selected for Stage 09 evaluation and integration |
| lua-language-server (LuaLS) | Language server for Lua | External executable |
| nvim-lspconfig | Additional language-server configurations | Deferred; requires a separate decision |

Use Neovim's built-in `vim.lsp.config()` and `vim.lsp.enable()` APIs as the initial architecture.

Do not add `nvim-lspconfig` automatically. Evaluate whether it supplies configurations or compatibility that the project actually needs. Record the decision before changing the plugin inventory.

Stage 09 does not include completion, snippets, formatting, linting, Mason, or debugging.

### Stage 10 — Completion and Snippets

| Plugin | Intended role | Policy |
|---|---|---|
| blink.cmp | Completion | Planned |
| friendly-snippets | Reusable snippets | Planned |

These plugins belong to Stage 10. Their presence in this inventory does not authorize installation before that stage.

### Stage 11 — Format and Lint

| Plugin | Intended role | Policy |
|---|---|---|
| conform.nvim | Formatting integration | Planned |
| Linting integration | Run configured linters and surface diagnostics | Candidate; select after evaluation |

Formatters and linters are external tools. The plugin integration does not replace their installation or version management.

The selected linting solution should be documented after its requirements, filetype support, and overlap with native diagnostics have been evaluated.

### Stage 12 — Git, Root, and Sessions

| Plugin or tool | Intended role | Policy |
|---|---|---|
| gitsigns.nvim | Git change indicators and hunk workflows | Planned |
| lazygit | Optional terminal Git interface | Optional external executable |
| Project-root integration | Consistent project context | Requires separate evaluation |
| Session integration | Restore selected workspace state | Requires separate evaluation |

Optional tools must be checked for availability before invocation. Missing optional executables should produce clear feedback rather than confusing errors.

Project-root and session plugins should not be admitted solely because they are common in other Neovim distributions.

### Stage 13 — Language Packs

This stage adds selected language-specific support after the foundational LSP, completion, and formatting stages.

Potential components include:

- Language servers.
- Tree-sitter parsers.
- Formatters and linters.
- Debug adapters.
- Language-specific configuration.

Each component must be selected for an explicitly supported language and documented in the dependency records.

This stage is not a commitment to install every tool or support every language.

### Stage 14 — Debugging

| Plugin or dependency | Intended role | Policy |
|---|---|---|
| nvim-dap | Debug Adapter Protocol client | Planned |
| nvim-dap-ui | Debugging interface | Planned |
| nvim-nio | Required asynchronous dependency where applicable | Dependency to document |
| Debug adapters | Connect to language runtimes and debuggers | External tools; configure selectively |

Debug adapters are not interchangeable with Neovim plugins. Their installation and compatibility requirements must be documented separately.

### Stage 15 — UI Polish

| Plugin or feature | Intended role | Policy |
|---|---|---|
| Snacks dashboard | Startup dashboard | Planned |
| Additional UI enhancements | Improve usability where justified | Candidate-based evaluation |

The dashboard should use a separate `lua/plugins/dashboard.lua` configuration module while retaining the shared Snacks setup path.

Additional UI plugins must demonstrate a clear benefit without introducing unnecessary startup cost or duplicate functionality.

### Stage 16 — Performance

No additional plugin is automatically admitted by this stage.

Evaluate startup and runtime behavior first. Lazy-loading may be introduced only where measurements justify it and compatibility with Neovim 0.12 has been verified.

### Stage 17 — Hardening

This stage consolidates testing, CI, dependency documentation, and reliability. It does not automatically introduce new plugins.

New dependencies discovered during hardening must go through the normal admission process.

## Deferred and Rejected Candidates

The following decisions must remain explicit rather than being inferred from another distribution's plugin list.

| Candidate | Current direction | Admission condition |
|---|---|---|
| nvim-lspconfig | Deferred | Reconsider after evaluating native LSP configuration needs |
| Mason | Not selected as the default tool manager | Reconsider only if a documented requirement outweighs the separate-tool-management policy |
| nvim-web-devicons | Not selected | Do not add without a concrete unmet requirement |
| project.nvim | Deferred for separate evaluation | Establish a specific project-root behavior that is not adequately served by existing configuration |
| zen-mode.nvim | Deferred for separate evaluation | Establish a clear use case and compare with available native or existing-plugin workflows |
| Additional Markdown or PDF workflow plugins | Future candidates | Evaluate when the relevant workflow stage and requirements are defined |

A deferred candidate is not a rejected plugin in all circumstances. It is simply not admitted into the current implementation without further evaluation.

## Repository Verification

Before changing an item's status, inspect the actual repository and validate the relevant behavior.

A useful verification sequence is:

1. Confirm whether the plugin is declared in the plugin-management configuration.
2. Confirm whether its setup module exists and is loaded.
3. Check whether its external dependencies are documented.
4. Run applicable syntax, formatting, and smoke checks.
5. Perform interactive verification when headless tests cannot establish the behavior.
6. Update the inventory and related documentation to match the verified result.

Do not infer installation from an inventory entry or completion from a commit message alone.

## Related Documentation

- `README.md` — project overview, installation, current status, and roadmap summary.
- `docs/architecture.md` — architectural principles and module boundaries.
- `docs/roadmap.md` — stage order and completion criteria.
- `docs/dependencies.md` — external tools and dependency requirements.
- `docs/Keymap-test.md` — interactive keymap verification.
- `docs/win-install.md` — Windows installation guidance.

As the project grows, update this inventory alongside plugin admission decisions and stage implementation rather than allowing it to become a separate, aspirational plugin list.
