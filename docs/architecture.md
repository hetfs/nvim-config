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

External plugins should provide a clearly justified capability rather than duplicate functionality that Neovim already supplies adequately.

### 2. Explicit plugin admission

A plugin is not installed merely because it appears in documentation, an inventory, or a future-stage plan.

**Approval is not installation.**

Each plugin must be evaluated against the project's requirements, alternatives, maintenance considerations, dependencies, and intended stage. Installation occurs only when the plugin is explicitly admitted into the implementation.

### 3. Modular configuration

Configuration responsibilities are separated into focused Lua modules.

- `init.lua` coordinates startup.
- `lua/config/` contains core Neovim configuration.
- `lua/plugins/` contains plugin-specific configuration and setup.

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

Native options, centralized mappings, autocommands, and future native LSP configuration belong here when their stage is reached.

### `lua/plugins/`

Owns plugin setup and plugin-specific behavior.

Plugin modules should have clear responsibilities. Multiple configuration files may be appropriate when they separate distinct features, but shared plugin setup should not be duplicated unnecessarily.

For example:

- Snacks uses one shared setup path, with dashboard configuration kept separate when that stage is implemented.
- `mini.nvim` is installed once as a shared repository; individual Mini modules are configured according to their respective stages.
- Snacks Picker and fzf-lua remain independent tools with their own configuration and mappings.

The presence of a Lua file under `lua/plugins/` is not, by itself, authorization to install its plugin.

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

Native functionality should not be redundantly redefined merely because it is available.

## Dependency Policy

Dependencies should be introduced only when required by the active stage.

The project distinguishes between:

1. Neovim itself.
2. External executables and system tools.
3. Neovim plugins.
4. Optional integrations and providers.

The dependency documentation should identify the purpose and installation expectations of relevant tools. Platform-specific setup instructions belong in the appropriate installation documentation or scripts.

Installing a plugin must not be treated as equivalent to installing the external executable it depends on.

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

## Stage Boundaries

The 17-stage roadmap governs implementation order.

Stages should be completed incrementally, with validation and documentation updated as part of the relevant work. Future-stage candidates must not be treated as installed or completed capabilities.

Performance optimization is deliberately deferred until Stage 16. At that stage, any decision to introduce lazy-loading should be supported by measurement and compatibility testing.

## Summary

The architecture is intentionally explicit: a small startup coordinator, direct module loading, focused configuration boundaries, native-first behavior, controlled plugin admission, separately managed external tools, and stage-based validation.

The objective is not to reproduce another distribution's architecture. It is to maintain a minimal, understandable Neovim configuration that can grow without losing predictability.
