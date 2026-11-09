# Architecture

## Purpose

`nvim-config` is a native-first, modular Neovim configuration built incrementally around Neovim's built-in capabilities.

Its architecture prioritizes a small, reliable foundation, explicit plugin admission, predictable startup behavior, and stage-by-stage validation.

> **Minimum installation. Compose the rest.**

The guiding principle is to build the smallest reliable foundation, compose additional capabilities deliberately, and validate each stage before proceeding.

## Design Principles

### 1. Native-first

Prefer Neovim's built-in capabilities when they satisfy the requirement.

Examples include:

- Native options and key mappings.
- Autocommands and autocmd groups.
- Built-in LSP configuration and activation APIs.
- Native commenting mappings and editing workflows.
- `vim.pack` for plugin management.
- Native session and project-related workflows where they satisfy the requirement.

External plugins should provide a clearly justified capability rather than duplicate functionality that Neovim already supplies adequately.

### 2. Explicit plugin admission

A plugin is not installed merely because it appears in documentation, an inventory, or a future-stage plan.

**Approval is not installation.**

Each plugin must be evaluated against the project's requirements, alternatives, maintenance considerations, dependencies, and intended stage. Installation occurs only when the plugin is explicitly admitted into the implementation.

A documented candidate is not necessarily approved, installed, or validated.

### 3. Modular configuration

Configuration responsibilities are separated into focused Lua modules.

- `init.lua` coordinates startup.
- `lua/config/` contains core Neovim configuration and shared behavior.
- `lua/plugins/` contains plugin-specific configuration and setup.
- `lua/langs/` contains project-owned language packs.

Modules should have clear responsibilities, avoid unnecessary coupling, and remain easy to inspect and validate.

### 4. Predictable startup

The startup configuration should remain small and explicit.

The project uses direct `require()` calls in `init.lua` rather than a generic module loader. Required modules should load through an identifiable startup path, and failures should remain visible instead of being silently swallowed.

Lazy-loading is not introduced prematurely. The configuration uses eager plugin loading through Stage 15. Stage 16 evaluates whether lazy-loading is justified by measured performance and verified behavior.

### 5. Incremental development

The configuration is developed through a defined 17-stage roadmap.

Each stage has a specific scope and validation requirements. Work should remain within the active stage until its implementation and required checks are complete.

A later stage must not be used to justify unrelated changes to an earlier one without a concrete reason.

### 6. External dependency separation

Neovim plugins and external executables are separate dependency categories.

Tools such as language servers, formatters, linters, debuggers, Git utilities, and compilers should be installed and managed outside Neovim's plugin manager unless a documented decision establishes otherwise.

The project does not adopt Mason as its default external-tool installation mechanism.

### 7. Explicit state changes

Operations that change user state should be intentional and understandable.

Examples include Git hunk operations, project navigation, and session management. Automatic behavior should be introduced only when its scope and consequences are justified.

In particular, session saving and restoration should remain explicit unless a future decision establishes a different policy.

## Runtime Requirements

- **Minimum supported version:** Neovim 0.12.0.
- **Current compatibility baseline:** Neovim 0.12.
- **Future target:** Neovim 0.13, after compatibility has been tested.

The configuration should check the minimum version before loading version-dependent modules.

Validation must use the supported baseline rather than assuming that behavior on a newer development build guarantees compatibility with the minimum version.

## Startup Architecture

The top-level `init.lua` is the startup coordinator. It should perform only the work needed to establish a predictable configuration environment and load the required modules.

The startup contract is:

1. Resolve the configuration root.
2. Add the configuration root to Neovim's runtime path where required.
3. Check the minimum supported Neovim version.
4. Load the core configuration modules directly.
5. Allow required-module failures to remain visible.

The current core modules are:

| Module | Responsibility |
|---|---|
| `lua/config/options.lua` | Native Neovim options |
| `lua/config/keymaps.lua` | Centralized user-facing key mappings |
| `lua/config/autocmds.lua` | Autocommands and related lifecycle behavior |

The startup file should retain direct module loading. The project does not require a generic loader, a separate `lua/config/init.lua`, or a failure-isolating abstraction merely to load these modules.

As later stages are implemented, their integration should preserve this explicit startup contract.

## Configuration Boundaries

### `init.lua`

Owns startup coordination, version validation, runtime-path setup, and direct module loading.

It should not become a general-purpose container for options, mappings, autocommands, or plugin implementation details.

### `lua/config/`

Owns core Neovim configuration and shared behavior.

Native options, centralized mappings, autocommands, and shared LSP lifecycle behavior belong here.

Shared behavior should be implemented once where practical, with plugin-specific modules delegating to the appropriate configuration module rather than creating duplicate mapping or lifecycle definitions.

### `lua/plugins/`

Owns plugin setup and plugin-specific behavior.

Plugin modules should have clear responsibilities. Multiple configuration files may be appropriate when they separate distinct features, but shared plugin setup should not be duplicated unnecessarily.

Examples include:

- **Gitsigns:** supplies Git change indicators and hunk-related workflows. Its buffer-local mappings are registered through the central keymap module.
- **project.nvim:** supplies project root detection and project navigation.
- **mini.nvim:** is installed once as a shared repository; individual Mini modules are configured according to their respective stages.
- **mini.sessions:** provides explicit session save, restore, and delete workflows through the shared Mini installation.
- **Snacks:** uses one shared setup path, with dashboard configuration kept separate when that stage is implemented.
- **Snacks Picker and fzf-lua:** remain independent tools with their own configuration and mappings.
- **nvim-lspconfig:** supplies maintained language-server definitions.
- **lazydev.nvim:** remains in its dedicated `lua/plugins/lazydev.lua` module.

The presence of a Lua file under `lua/plugins/` is not, by itself, authorization to install its plugin.

Plugin modules should not imply that installing a plugin also installs its external executables or language servers.

### `lua/langs/`

Owns project-specific language packs and their language-specific configuration.

The language-pack boundary separates language-specific declarations from shared LSP lifecycle behavior and plugin installation.

The intended structure is:

| Path | Responsibility |
|---|---|
| `lua/langs/init.lua` | Discover project-owned language packs, evaluate their declarations, and coordinate server configuration and activation |
| `lua/langs/lua.lua` | Declare Lua language-server support and LuaLS-specific settings |
| Future `lua/langs/*.lua` modules | Declare support for additional languages when admitted in their designated stages |

#### Language-pack discovery

`lua/langs/init.lua` must discover language packs only from this repository's own `lua/langs/` directory.

It must not treat arbitrary `langs/` modules elsewhere on Neovim's runtime path as project-owned packs. Discovery should be deterministic so the registry processes packs in a predictable order.

The registry is responsible for coordinating the declarations provided by the discovered packs. It should distinguish configured servers from missing or unknown server configurations and avoid repeated setup effects when initialization is invoked more than once.

#### Language-pack contract

A language pack declares the language-server names it supports and any server-specific configuration overrides required by the project.

The registry uses these declarations to coordinate server configuration and activation. A language pack should remain focused on its language-specific requirements rather than independently reimplementing shared LSP lifecycle behavior.

For Lua, the initial language pack configures the LuaLS-specific settings:

- LuaJIT runtime.
- `vim` recognized as a global for diagnostics.
- `workspace.checkThirdParty = false`.
- Telemetry disabled.

LuaLS itself is an external executable and must be available on `PATH`. Its installation and updates are managed outside the Neovim plugin manager.

#### Server-definition and activation boundary

`nvim-lspconfig` provides maintained server definitions. Neovim's native `vim.lsp.config()` and `vim.lsp.enable()` APIs remain the interfaces used to configure and activate language servers.

Language packs should apply only the overrides needed by this project. They must not independently duplicate maintained server defaults such as `cmd`, `filetypes`, or `root_markers` without a demonstrated need.

This avoids unnecessary configuration drift and lets the maintained server definitions provide their intended defaults. Overrides remain appropriate when the project has a specific requirement that those defaults do not satisfy.

The legacy `require("lspconfig")` configuration interface is not part of this architecture.

#### LSP lifecycle and keymaps

Shared LSP attachment behavior remains configuration-owned.

The configuration registers an `LspAttach` autocmd and delegates buffer-local mapping registration to `lua/config/keymaps.lua`. The `gd` and `gD` mappings remain buffer-local and are installed when an LSP client attaches to a buffer.

Their responsibilities are:

- `gd` — go to definition.
- `gD` — go to declaration.

Language packs should not independently register duplicate attachment autocmds or redefine these shared mappings.

Automated tests should validate pack discovery, declarations, server configuration, and registry behavior. Interactive verification must separately confirm that LuaLS actually attaches to Lua buffers and provides the expected language features.

The language-pack registry does not imply that completion, snippets, formatting, linting, debugging, Mason, or lazy-loading are included in Stage 09. Those remain separate decisions governed by the roadmap.

## Git, Project Navigation, and Sessions

These workflows have separate responsibilities and dependency boundaries.

### Git integration

Git is an external executable and a core dependency for Git-based workflows.

Gitsigns integrates Git change information into Neovim and provides hunk-related actions. It does not install Git.

User-facing Gitsigns mappings are registered centrally in `lua/config/keymaps.lua` and are buffer-local when Gitsigns attaches.

The presence of Git and Gitsigns does not by itself prove that every Git workflow has been configured or tested.

### Project root detection

`project.nvim` provides project root detection and project navigation.

Project detection can use Git-related markers and other configured root indicators. The plugin does not install Git or other external tools.

Project root detection must remain distinct from automatic working-directory changes. The current configuration disables automatic directory changes, so identifying a project root does not imply that Neovim's working directory changes automatically.

Project detection and navigation must be verified through the actual configured workflow.

### Session management

`mini.sessions` uses the existing shared `mini.nvim` installation. It does not require a second installation of the shared repository.

The current configuration provides explicit session save, restore, and delete operations. Automatic session reads and writes are disabled.

Session management is separate from project root detection and Git integration. A saved session does not guarantee that external tools are installed or that a language server will successfully attach when the session is restored.

### Optional terminal integrations

Lazygit is an optional external terminal application, not a Neovim plugin and not a core dependency.

If a Lazygit mapping is provided, it must check whether the `lazygit` executable is available before attempting to launch it. If the executable is missing, the configuration should display a clear warning.

Git and Neovim plugins must not be treated as installers for Lazygit.

## Plugin Management

The project uses Neovim's native `vim.pack` plugin manager.

Plugin decisions follow these rules:

- Prefer native functionality when it is sufficient.
- Evaluate plugins individually and admit them explicitly.
- Avoid duplicate installations of shared plugin repositories.
- Keep plugin setup and external executable installation conceptually separate.
- Avoid premature lazy-loading.
- Document material architectural decisions and rejected alternatives when they affect future work.

The project does not use `lazy.nvim` as its plugin manager.

## Keymap Policy

User-facing mappings are centralized in `lua/config/keymaps.lua` wherever practical.

Mappings should:

- Have a clear purpose.
- Include a meaningful `desc` where supported and appropriate.
- Avoid conflicts with established native behavior.
- Be validated against the intended mode and workflow.

Plugin-specific actions may require plugin APIs, but their user-facing mappings should remain centralized where the design permits.

Gitsigns mappings are buffer-local and registered when the plugin attaches to a buffer. Session mappings invoke explicit save, restore, and delete operations. Project navigation remains separate from fzf-lua's picker-resume workflow.

Snacks Picker and fzf-lua configuration and mappings must remain independent.

LSP mappings follow the same policy. The shared `LspAttach` handler requests buffer-local mappings from `lua/config/keymaps.lua` rather than defining separate copies in individual language packs.

Native functionality should not be redundantly redefined merely because it is available.

## Dependency Policy

Dependencies should be introduced only when required by the active stage.

The project distinguishes between:

1. Neovim itself.
2. External executables and system tools.
3. Neovim plugins.
4. Language-server executables and parser dependencies.
5. Optional integrations and providers.

The dependency documentation should identify the purpose and installation expectations of relevant tools. Platform-specific setup instructions belong in the appropriate installation documentation or scripts.

Installing a plugin must not be treated as equivalent to installing the external executable it depends on.

Examples:

- Git is installed and managed outside Neovim's plugin manager.
- `fd` supports file discovery.
- `rg` (ripgrep) supports content search.
- `fzf` provides fuzzy selection for compatible workflows such as fzf-lua.
- A compiler and the required Tree-sitter CLI support parser-related build workflows.
- LuaLS is an external language-server executable.
- Lazygit is an optional external terminal application.
- `nvim-lspconfig` supplies maintained server definitions.
- Neovim's native LSP APIs configure and activate servers.
- Language packs declare supported servers and project-specific overrides.
- `lazydev.nvim` improves Lua development context; it does not install or manage LuaLS.
- Mason is not part of the default configuration.

The Windows dependency setup script has a defined scope. Tools outside that scope must be installed and verified separately rather than assumed to be covered by a successful script run.

## Validation

Architecture changes must preserve the project's minimum supported version and explicit startup behavior.

Validation should grow alongside implementation and may include:

- Lua syntax checks.
- Formatting checks.
- Headless smoke tests for native configuration contracts.
- Plugin configuration checks appropriate to the active stage.
- Interactive verification for workflows that cannot be fully tested headlessly.
- CI checks as the hardening stage establishes them.

A passing syntax check does not prove that a mapping, plugin, language server, or interactive workflow behaves correctly. Tests must match the claim being made.

For the language-pack registry, tests should verify that discovery is restricted to the project-owned directory, pack declarations are processed deterministically, server-specific overrides are applied as intended, and repeated initialization does not duplicate setup effects.

The existence of a server configuration does not prove that the external executable is available or that a server has attached to a buffer. These conditions require separate verification.

Git workflows should be tested in a suitable repository. Project navigation should be tested against representative root markers. Session save and restore should be verified interactively, with explicit deletion tested carefully. Optional executable integrations should be tested both when the executable is available and when it is missing.

## Stage Boundaries

The 17-stage roadmap governs implementation order.

Stages should be completed incrementally, with validation and documentation updated as part of the relevant work. Future-stage candidates must not be treated as installed or completed capabilities.

Performance optimization is deliberately deferred until Stage 16. At that stage, any decision to introduce lazy-loading should be supported by measurement and compatibility testing.

Stage 09 establishes the LSP and language-pack foundation. Completion and snippets, formatting and linting, debugging, Mason, and lazy-loading changes remain outside its scope.

Stage 12 introduces Git integration, project root detection and navigation, and explicit session management. Implementation and initial verification do not by themselves mean that the stage is complete: the relevant documentation, dependency records, keymap references, automated checks, and remaining closeout requirements must also be reconciled.

## Summary

The architecture is intentionally explicit: a small startup coordinator, direct module loading, focused configuration boundaries, native-first behavior, controlled plugin admission, separately managed external tools, project-owned language packs, intentional state changes, and stage-based validation.

The objective is not to reproduce another distribution's architecture. It is to maintain a minimal, understandable Neovim configuration that can grow without losing predictability.
