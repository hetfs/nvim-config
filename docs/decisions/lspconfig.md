# ADR: nvim-lspconfig

- **Status:** Accepted
- **Date:** 2026-10-24

## Context

This project prioritizes Neovim's built-in capabilities and adds plugins only when their benefits justify the additional dependency.

Neovim provides a native Language Server Protocol (LSP) client and native APIs for configuring and enabling language servers. The project will continue to use these APIs as its primary interface for LSP configuration and activation.

The `nvim-lspconfig` project provides maintained configurations for individual language servers. These definitions reduce the need for this project to duplicate server-specific defaults, such as executable commands, supported filetypes, and workspace root markers.

Adopting `nvim-lspconfig` does not require adopting its legacy configuration interface. The project can use its server definitions alongside Neovim's native `vim.lsp.config()` and `vim.lsp.enable()` APIs.

Stage 09 — LSP and `lazydev` establishes the initial language-server workflow. Its scope is deliberately limited to Lua development support, with additional language support introduced in later stages.

Language-server configuration and activation must remain separate from installing and managing the external server executables.

## Decision

**Accept `nvim-lspconfig` as a Stage 09 dependency for maintained language-server definitions.**

Use `nvim-lspconfig` together with Neovim's native LSP APIs:

- Use `vim.lsp.config()` to configure language servers and apply project-specific overrides.
- Use `vim.lsp.enable()` to enable the selected language servers.
- Use the server definitions supplied by `nvim-lspconfig` instead of unnecessarily maintaining duplicate defaults.
- Do not use the legacy `require("lspconfig")` interface.
- Keep language-server installation and executable management outside the Neovim plugin configuration.
- Introduce additional language servers only in their designated roadmap stages.

For Stage 09, LuaLS (`lua-language-server`) is the initial language server. Its executable must be installed and available on `PATH` independently of Neovim and `nvim-lspconfig`.

`lazydev.nvim` remains a separate development helper that improves LuaLS awareness of Neovim and installed Lua libraries. It does not install or manage LuaLS.

Python language-server integration remains deferred to Stage 13. Accepting `nvim-lspconfig` does not authorize implementing Python support ahead of that stage.

## Alternatives Considered

### 1. Maintain all server definitions directly

Configure language servers using Neovim's native APIs without adopting `nvim-lspconfig`.

**Advantages**

- Minimizes third-party dependencies.
- Keeps server configuration entirely within the project.
- Makes every maintained server setting explicit.

**Trade-offs**

- Requires the project to maintain server-specific defaults.
- Can duplicate configuration already maintained by the upstream project.
- Increases the maintenance burden as the supported language inventory grows.

**Outcome:** Not selected as the default approach for server definitions. Native APIs remain the configuration and activation interface, while `nvim-lspconfig` supplies maintained definitions.

### 2. Adopt `nvim-lspconfig` and use its legacy interface

Configure servers through `require("lspconfig")` and the plugin's legacy setup interface.

**Advantages**

- Familiar to users of many existing Neovim configurations.
- Provides an established setup pattern.

**Trade-offs**

- Introduces a separate configuration interface when Neovim already provides native LSP APIs.
- Does not align with the project's chosen native-first configuration architecture.

**Outcome:** Rejected. The project will not use the legacy `require("lspconfig")` interface.

### 3. Use `nvim-lspconfig` definitions with native Neovim APIs

Use the plugin to supply maintained server definitions while retaining native configuration and activation.

**Advantages**

- Avoids unnecessary duplication of upstream server defaults.
- Preserves the project's native-first LSP workflow.
- Keeps server configuration and activation explicit.
- Provides a straightforward path for adding language support in later stages.

**Trade-offs**

- Adds a third-party dependency.
- Requires compatibility checks against the minimum supported Neovim version.
- Requires the project to understand how upstream defaults interact with local overrides.

**Outcome:** Selected.

### 4. Defer broad language-server support

Introduce only the language servers needed for each roadmap stage.

**Advantages**

- Keeps each stage focused.
- Avoids premature language-specific configuration.
- Allows dependencies and tooling to follow demonstrated requirements.

**Trade-offs**

- Additional language servers require their own implementation and validation when their stages begin.

**Outcome:** Selected as the language-support strategy. Stage 09 is limited to LuaLS; Python support remains deferred to Stage 13.

## Evaluation Criteria

The selected approach must satisfy the following criteria:

1. **Required functionality:** Support the language servers and capabilities explicitly included in the current stage.
2. **Configuration complexity:** Reuse maintained upstream definitions where appropriate rather than duplicating them without justification.
3. **Compatibility:** Verify operation against the minimum supported Neovim version, currently Neovim 0.12 or later.
4. **Maintainability:** Keep project-specific overrides explicit and limited to requirements not already handled by upstream defaults.
5. **Extensibility:** Allow future language packs to add server-specific configuration without redesigning the LSP architecture.
6. **Dependency cost:** Keep the plugin's role narrow and document why it is included.
7. **Separation of concerns:** Separate server definitions, native LSP configuration and activation, language-specific overrides, and external executable management.
8. **Validation:** Test configuration loading, server startup, attachment, diagnostics, and the required LSP capabilities in a real Neovim session.

## Relationship to lazydev

`lazydev.nvim` is selected separately for the Lua development workflow.

Its purpose is to improve LuaLS awareness of Neovim APIs and installed Lua libraries. It does not replace the language server, install the server executable, or determine how servers are configured and enabled.

The decision to use `lazydev.nvim` does not determine whether `nvim-lspconfig` is required. Each dependency has a distinct responsibility within the Stage 09 architecture.

## Consequences

The accepted decision establishes the following boundaries:

- `nvim-lspconfig` is an approved dependency for maintained language-server definitions.
- Neovim's native `vim.lsp.config()` and `vim.lsp.enable()` APIs remain the configuration and activation interface.
- The legacy `require("lspconfig")` interface is not used.
- LuaLS is the initial server for Stage 09 and must be installed externally.
- `lazydev.nvim` provides Lua development enhancements but does not manage the LuaLS executable.
- Python language-server support remains deferred to Stage 13.
- Mason is not part of the default configuration.
- Language-specific settings belong in the corresponding language pack, while shared LSP attachment behavior and keymaps remain configuration-owned.
- The plugin inventory, architecture documentation, roadmap, and dependency documentation must reflect these boundaries.

The project retains explicit control over which language servers are enabled. Accepting `nvim-lspconfig` does not imply enabling every server definition it provides.

## Validation

Before Stage 09 can be considered complete:

- Confirm that the configuration loads without errors on the minimum supported Neovim version.
- Verify that the selected LuaLS configuration is available through Neovim's native LSP configuration API.
- Confirm that `lua-language-server` is available and starts successfully in the intended environment.
- Verify that LuaLS attaches to a suitable Lua buffer and workspace.
- Test diagnostics, hover, and the configured buffer-local navigation mappings.
- Confirm that missing executables or unavailable servers are reported clearly.
- Run the applicable syntax checks, smoke tests, formatting checks, and `git diff --check`.
- Record any limitations discovered during live testing.

Successful Lua syntax validation alone is not proof that the LSP workflow functions correctly. A configured server is not considered operational until attachment and required capabilities have been verified.

## Follow-up

Implement and validate the Stage 09 workflow using the accepted architecture.

Update the plugin inventory, architecture documentation, roadmap, and dependency documentation to reflect the decision. Keep Python language support deferred to Stage 13.

Revisit this ADR only if the upstream definitions, supported Neovim APIs, or project requirements change enough to justify reconsidering the dependency.
