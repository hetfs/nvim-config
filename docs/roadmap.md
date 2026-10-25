# Roadmap

## Purpose

This roadmap defines the implementation order for `nvim-config`, a native-first, modular Neovim configuration.

Each stage introduces a defined set of capabilities, with validation and documentation updated alongside the implementation. The roadmap is intended to keep development incremental, prevent scope creep, and make plugin admission deliberate.

> **Minimum installation. Compose the rest.**

**Stage policy:** A stage is complete only when its implementation and required validation are complete. Listing a plugin or capability in this roadmap does not authorize its installation.

## Current Status

Stages 01–06 are complete. Stage 07 closeout and Stage 08 final closeout must be tracked against their implementation and validation requirements before proceeding.

Stage 09 is the next major integration stage after the preceding stages have been closed out.

> Update this status whenever a stage is formally completed. Do not infer completion from the presence of configuration files alone.

## Stage Overview

| Stage | Name | Scope |
|---|---|---|
| 01 | First Init | Establish the initial configuration and startup contract |
| 02 | Keymaps and Autocommands | Add foundational mappings and autocommands |
| 03 | Modules | Establish the modular configuration structure |
| 04 | Native Workflows | Configure and validate useful native Neovim workflows |
| 05 | `vim.pack` and Catppuccin | Introduce native plugin management and the colorscheme |
| 06 | which-key and mini.icons | Improve mapping discovery and icon integration |
| 07 | Snacks Navigation | Establish navigation tools and selected Mini modules |
| 08 | Treesitter | Integrate Tree-sitter-based syntax parsing and highlighting |
| 09 | LSP and lazydev | Establish native LSP configuration, a project-local language-pack registry, and Lua development support |
| 10 | Completion and Snippets | Add completion and snippet workflows |
| 11 | Format and Lint | Integrate formatting and linting |
| 12 | Git, Root, and Sessions | Add Git integration, project-root behavior, and session workflows |
| 13 | Language Packs | Extend support for selected languages |
| 14 | Debugging | Integrate debugging workflows |
| 15 | UI Polish | Complete selected interface enhancements and dashboard work |
| 16 | Performance | Measure startup and runtime behavior; optimize where justified |
| 17 | Hardening | Consolidate validation, CI, documentation, and reliability |

## Stage Details

### Stage 01 — First Init

**Objective:** Establish the smallest working configuration.

Scope:

- Create the top-level `init.lua`.
- Establish the minimum supported Neovim version.
- Keep startup behavior explicit and understandable.
- Validate that Neovim can load the configuration.

**Completion criteria:**

- The configuration starts on the supported Neovim baseline.
- Version validation behaves as intended.
- The initial startup path is documented and testable.

### Stage 02 — Keymaps and Autocommands

**Objective:** Establish foundational configuration behavior.

Scope:

- Add `lua/config/options.lua`.
- Add `lua/config/keymaps.lua`.
- Add `lua/config/autocmds.lua`.
- Establish a named autocommand group.
- Add descriptive mappings and foundational native options.
- Introduce syntax and smoke checks.

**Completion criteria:**

- Core modules load through the startup path.
- Representative options, mappings, and autocommands pass smoke checks.
- Formatting and syntax validation pass.

### Stage 03 — Modules

**Objective:** Separate responsibilities without obscuring startup behavior.

Scope:

- Organize core configuration into focused modules.
- Retain direct `require()` calls in `init.lua`.
- Keep the module layout straightforward and inspectable.

**Completion criteria:**

- Core modules have clear responsibilities.
- Startup loading remains explicit.
- Required modules do not fail silently.
- Syntax and smoke checks validate the modular configuration.

### Stage 04 — Native Workflows

**Objective:** Establish useful workflows using Neovim's built-in capabilities before adding more plugins.

Scope:

- Review native editing and navigation capabilities.
- Validate relevant key mappings and mode-specific behavior.
- Resolve the native commenting workflow.
- Document interactive checks that cannot be adequately verified through headless tests.

**Completion criteria:**

- The selected native workflows work as intended.
- The native commenting issue is resolved.
- Documentation reflects the verified behavior.
- The stage's required validation is complete.

### Stage 05 — `vim.pack` and Catppuccin

**Objective:** Introduce native plugin management and the selected colorscheme.

Scope:

- Use Neovim's built-in `vim.pack` plugin manager.
- Add Catppuccin through an explicit plugin configuration.
- Keep plugin admission separate from general candidate documentation.

**Completion criteria:**

- Plugin management follows the project's native-first policy.
- The colorscheme is configured and validated.
- The configuration does not depend on `lazy.nvim`.

### Stage 06 — which-key and mini.icons

**Objective:** Improve mapping discovery and icon support.

Scope:

- Add which-key.
- Add `mini.icons`.
- Establish the shared `mini.nvim` installation when the first Mini module is admitted.
- Keep mapping definitions centralized where practical.

**Completion criteria:**

- Plugin setup follows the established admission policy.
- Mapping descriptions are useful for discovery.
- Mini modules use the shared repository installation rather than duplicate plugin entries.

### Stage 07 — Snacks Navigation

**Objective:** Establish the selected navigation and editing enhancements.

Scope:

- Integrate Snacks.
- Integrate fzf-lua as an independent navigation tool.
- Integrate flash.
- Configure the selected Mini modules, including AI, movement, and surround functionality.
- Keep Snacks Picker and fzf-lua configuration and mappings independent.
- Avoid redundant setup for shared plugin repositories.

**Completion criteria:**

- Each admitted plugin has a clear responsibility.
- Navigation and editing workflows are validated.
- Plugin configuration and keymaps are documented.
- Required stage checks pass before closeout.

### Stage 08 — Treesitter

**Objective:** Add Tree-sitter-based syntax parsing and highlighting.

Scope:

- Configure the Tree-sitter plugin.
- Define the selected parser policy.
- Keep compiler and other external prerequisites documented separately from the plugin.
- Validate the configuration against the supported Neovim version.

**Completion criteria:**

- Plugin configuration is valid.
- Required parsers and external prerequisites are addressed.
- Syntax, smoke, and applicable interactive checks pass.
- Documentation and stage closeout are complete.

### Stage 09 — LSP and lazydev

**Objective:** Establish a project-local language-pack registry, configure and activate language servers through Neovim's native LSP APIs, and improve Lua development support.

**Scope:**

1. Add `nvim-lspconfig` through Neovim's native `vim.pack` plugin manager. Use it to supply maintained language-server definitions; do not use its legacy `require("lspconfig")` configuration interface.
2. Keep `lazydev.nvim` in its dedicated `lua/plugins/lazydev.lua` module.
3. Introduce `lua/langs/init.lua` as the project-local language-pack registry. Restrict pack discovery to this repository's own `lua/langs/` directory and make discovery deterministic.
4. Add `lua/langs/lua.lua` with the existing LuaLS-specific settings:
   - LuaJIT runtime.
   - `vim` as a recognized global for diagnostics.
   - `workspace.checkThirdParty = false`.
   - Disabled telemetry.
5. Configure and activate language servers using Neovim's native `vim.lsp.config()` and `vim.lsp.enable()` APIs. Use the server definitions provided by `nvim-lspconfig` rather than unnecessarily duplicating their defaults.
6. Preserve the `LspAttach` lifecycle behavior and the buffer-local `gd` and `gD` mappings, with mapping definitions remaining in `lua/config/keymaps.lua`.
7. Test the registry and configuration contract with automated checks, then verify actual LuaLS attachment interactively, including diagnostics and applicable language features.

LuaLS (`lua-language-server`) remains an external executable and must be available on `PATH`. Its installation and updates are managed through the system package manager, `mise`, or another explicitly chosen external tool manager. `lazydev.nvim` does not install or manage LuaLS. Mason is not part of the default configuration.

**Completion criteria:**

- `nvim-lspconfig` and `lazydev.nvim` are configured in their designated plugin modules.
- The registry discovers only project-local language packs and handles server status and activation predictably.
- The Lua language pack preserves the approved LuaLS settings.
- Server configuration and activation use Neovim's native LSP APIs.
- The `LspAttach` autocmd and buffer-local `gd` and `gD` mappings work as intended.
- Automated checks validate language-pack discovery, server configuration, and registry behavior without requiring a live language-server process.
- Interactive verification confirms that LuaLS actually attaches to Lua buffers and provides the expected features.
- Syntax and formatting checks pass, and the documentation reflects the implementation.

**Explicitly out of scope:**

- Completion and snippets.
- Formatting and linting.
- Mason or Mason-based tool installation.
- Debugging and DAP integration.
- Lazy-loading changes or performance optimization.

These capabilities remain assigned to their designated later stages. Stage 09 must not expand to absorb them.

### Stage 10 — Completion and Snippets

**Objective:** Add completion and snippet workflows after the LSP foundation is established.

Scope:

- Evaluate and configure blink.cmp.
- Add friendly-snippets.
- Define completion and snippet behavior.
- Integrate with the existing LSP setup without expanding Stage 09 retroactively.

**Completion criteria:**

- Completion and snippet workflows operate as intended.
- Plugin setup and mappings are documented.
- Relevant dependencies and validation are addressed.

### Stage 11 — Format and Lint

**Objective:** Establish consistent formatting and linting workflows.

Scope:

- Integrate conform.nvim for formatting.
- Add the selected linting integration after evaluating its requirements.
- Keep formatter and linter executables separate from plugin installation.
- Define supported tools and filetypes deliberately.

**Completion criteria:**

- Formatting behavior is explicit and testable.
- Linting behavior is documented and appropriately scoped.
- External tool prerequisites are recorded.
- Validation does not depend solely on the presence of plugin files.

### Stage 12 — Git, Root, and Sessions

**Objective:** Add project-aware workflows and Git integration.

Scope:

- Integrate gitsigns.
- Evaluate project-root behavior.
- Add session functionality where justified.
- Keep optional command-line integrations optional.
- Check for executables before invoking them and provide clear feedback when unavailable.

**Completion criteria:**

- Git and project workflows are predictable.
- Session behavior is documented and tested.
- Optional dependencies fail clearly rather than producing confusing errors.

### Stage 13 — Language Packs

**Objective:** Extend the configuration for selected programming languages.

Scope:

- Define supported language profiles.
- Document language servers, formatters, linters, parsers, and other required external tools.
- Add language-specific configuration incrementally.
- Keep language support modular.

**Completion criteria:**

- Each supported language has a documented dependency set.
- Language-specific behavior is validated.
- The configuration avoids installing unrelated tools by default.

### Stage 14 — Debugging

**Objective:** Establish a deliberate debugging workflow.

Scope:

- Evaluate and integrate nvim-dap.
- Add the required DAP UI and adapter components if admitted.
- Document `nvim-nio` and other required dependencies.
- Treat debug adapters as separate dependencies where applicable.

**Completion criteria:**

- Debugger setup is explicit.
- Supported debug workflows are documented and tested.
- Missing adapters or external tools produce clear diagnostic information.

### Stage 15 — UI Polish

**Objective:** Add selected interface enhancements after core workflows are stable.

Scope:

- Configure the Snacks dashboard in a separate `lua/plugins/dashboard.lua` module.
- Keep the shared Snacks setup in one place.
- Evaluate remaining UI improvements against the project's minimalism principles.

**Completion criteria:**

- UI modules have clear responsibilities.
- Existing plugin setup is not duplicated.
- UI changes preserve startup reliability and established workflows.

### Stage 16 — Performance

**Objective:** Measure and improve performance only where evidence supports a change.

Scope:

- Measure startup behavior.
- Identify expensive configuration or plugin-loading paths.
- Evaluate lazy-loading only when it addresses a measured problem.
- Verify that any loading changes work on the minimum supported Neovim version.

**Completion criteria:**

- Performance changes have a clear justification.
- Loading behavior is validated rather than assumed.
- Startup reliability and functionality are preserved.
- Measurements and relevant trade-offs are documented.

### Stage 17 — Hardening

**Objective:** Consolidate project reliability and maintainability.

Scope:

- Review syntax and formatting checks.
- Strengthen smoke tests and integration checks.
- Establish or refine CI.
- Audit documentation against the implementation.
- Review plugin admission, dependencies, startup behavior, and platform-specific setup.
- Remove obsolete instructions and resolve known inconsistencies.

**Completion criteria:**

- Required checks are repeatable.
- Documentation reflects the actual implementation.
- Supported-platform expectations are explicit.
- Known failures and unsupported assumptions are addressed.
- The configuration is maintainable without relying on undocumented setup steps.

## Cross-Stage Rules

The following rules apply throughout the roadmap:

1. **One stage at a time.** Complete the active stage before beginning unrelated work in the next stage.
2. **Validate before closeout.** A file existing in the repository is not proof that its behavior works.
3. **Document dependencies.** Plugin installation does not install the external executables a plugin may require.
4. **Keep mappings discoverable.** Centralize user-facing mappings where practical and use meaningful descriptions.
5. **Avoid duplicate setup.** Shared plugin repositories and common setup paths should not be configured redundantly.
6. **Preserve native behavior.** Do not recreate built-in functionality without a concrete reason.
7. **Defer optimization.** Lazy-loading belongs to Stage 16 unless a documented compatibility or correctness issue requires earlier intervention.
8. **Keep scope explicit.** A future-stage item remains a candidate until its stage admits and implements it.

## Updating This Roadmap

When a stage changes status:

- Update the current status near the top of this document.
- Record completion only after required implementation and validation are confirmed.
- Update related documentation, including plugin inventory, dependencies, keymaps, and testing guidance where applicable.
- Keep rejected or deferred candidates clearly distinguished from installed capabilities.
- Avoid claiming a stage is complete based solely on a commit message or configuration file.

The roadmap should describe the repository's actual state, not an aspirational state.
