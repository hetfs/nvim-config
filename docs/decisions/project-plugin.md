# ADR: Project Management with project.nvim

- **Status:** Accepted for Stage 12
- **Date:** 2026-10-25

## Context

The `nvim-config` project needs predictable project-root detection and project-aware workflows while preserving its native-first, modular architecture.

Stage 12 — Git, Root, and Sessions — is responsible for integrating Git change indicators, establishing project context, and evaluating session workflows.

The project has selected [`DrKJeff16/project.nvim`](https://github.com/DrKJeff16/project.nvim) for project discovery, root detection, project selection, and project history. This decision does not reopen or change the completed Stage 09 LSP implementation.

The governing principle remains:

> **Minimum installation. Compose the rest.**

## Decision

Accept `DrKJeff16/project.nvim` for implementation in Stage 12.

The plugin will be managed through Neovim's native `vim.pack` plugin manager and configured in a dedicated `lua/plugins/project.lua` module.

The following boundaries apply:

- **Plugin management:** Use `vim.pack`.
- **Project management:** Use project.nvim for the selected project-aware workflows.
- **LSP:** Preserve the existing native `vim.lsp.config()` and `vim.lsp.enable()` architecture from Stage 09.
- **Snacks:** Keep the existing Snacks configuration independent. Enable project.nvim's Snacks integration only if a concrete requirement justifies it.
- **fzf-lua:** Keep its configuration and mappings independent from Snacks and project.nvim. Do not enable another integration by default.
- **Sessions:** Evaluate session behavior separately. Project detection alone must not be treated as complete editor-session restoration.
- **External tools:** Continue managing executables outside the Neovim plugin manager. Verify `fd` availability before relying on features that require it.
- **Loading:** Keep the plugin eagerly loaded through Stage 15. Performance-driven lazy-loading belongs to Stage 16.
- **Root abstraction:** Do not create `lua/config/root.lua` by default. Introduce a separate abstraction only if a demonstrated requirement cannot be handled cleanly by the selected plugin and existing configuration.
- **Keymaps:** Keep user-facing mappings centralized in `lua/config/keymaps.lua`, use meaningful descriptions, and check for collisions before introducing mappings. Preserve existing mappings unless a separate decision changes them.

Review the plugin's upstream defaults before finalizing configuration. Settings affecting root detection, working-directory changes, history, LSP behavior, or optional picker integrations must be chosen deliberately rather than copied without evaluation.

Acceptance of this ADR records the architectural decision. It does not mean the plugin has been installed, configured, or validated.

## Alternatives Considered

### 1. Use native capabilities and existing tools

Retain native Neovim behavior and add only the minimum project-related configuration necessary.

**Advantages:**

- Fewer dependencies.
- Less plugin-specific behavior.
- A smaller configuration surface.

**Trade-offs:**

- Project discovery, history, and switching may require additional implementation.
- Root detection and session behavior may need coordination across separate modules.

### 2. Use `DrKJeff16/project.nvim`

Adopt the selected fork for project discovery, root detection, project selection, and history.

**Advantages:**

- Consolidates the selected project-management workflows in a dedicated plugin.
- Avoids maintaining a custom root-detection implementation without a demonstrated need.
- Provides a defined integration point for future project-aware workflows.

**Trade-offs:**

- Adds a plugin dependency and configuration surface.
- Requires review of upstream defaults and compatibility with the existing configuration.
- Some features, particularly session-related workflows, may depend on external executables or additional configuration.

**Decision:** Select this alternative for Stage 12, subject to implementation and validation.

## Configuration Principles

The implementation should follow these principles:

1. Prefer Git-root detection and the plugin's supported project markers. Validate marker precedence against representative repositories.
2. Keep automatic working-directory behavior explicit. Do not enable `enable_autochdir` without a demonstrated requirement.
3. Select a working-directory scope deliberately and test behavior when switching projects, buffers, windows, and tabs.
4. Retain reasonable upstream history defaults unless testing establishes a need to change them.
5. Keep Snacks and fzf-lua integrations disabled unless a specific workflow justifies enabling one.
6. Avoid duplicating project detection in custom autocommands or a separate root module.
7. Preserve existing keymap ownership and descriptions. Check for collisions before introducing project mappings.
8. Keep optional command-line tools optional and report missing dependencies clearly.

These principles define implementation constraints, not verified runtime behavior.

## Stage 12 Validation

Before Stage 12 can be marked complete, validate:

- The plugin is installed through `vim.pack` and loaded from `lua/plugins/project.lua`.
- Git repositories are detected as expected.
- Recognized project markers behave predictably.
- Project selection and history work as configured.
- Working-directory behavior is consistent when switching projects.
- Project detection does not regress the existing LSP setup or language-pack behavior.
- Existing Snacks and fzf-lua workflows remain independent unless an integration is explicitly enabled.
- Session behavior is tested and documented separately from root detection.
- Features requiring `fd` behave correctly when the executable is present; missing-tool behavior is documented and handled clearly.
- Keymaps do not conflict with existing mappings.
- Syntax, formatting, smoke tests, and applicable interactive checks pass.
- The README, plugin inventory, dependency documentation, and keymap documentation reflect the verified implementation.

Do not mark a feature validated merely because its plugin configuration loads or its command is registered.

## Consequences

### Positive

- Project management has an explicit owner.
- A separate root abstraction is not introduced without need.
- Existing LSP and navigation responsibilities remain clearly separated.
- Optional integrations can be evaluated without coupling existing pickers together.
- Stage 12 has concrete validation requirements.

### Trade-offs

- The configuration adopts another dependency.
- The selected plugin's behavior and defaults must be tested against actual project workflows.
- Session behavior may require a separate decision after project-management workflows are implemented.

## Follow-up

Implement this decision during **Stage 12 — Git, Root, and Sessions**.

Keep Stage 09 complete. Keep Stage 12 planned until its implementation and required validation are complete. Update the roadmap, plugin inventory, dependency documentation, and keymap documentation as the implementation establishes verified behavior.
