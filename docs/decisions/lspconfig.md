# ADR: nvim-lspconfig

- **Status:** Deferred
- **Date:** 2026-10-24

## Context

This project prioritizes Neovim's built-in capabilities and adds plugins only when their benefits justify the additional dependency.

Neovim provides a native Language Server Protocol (LSP) client. The project can configure supported language servers through Neovim's native LSP APIs without making `nvim-lspconfig` an automatic requirement.

The `nvim-lspconfig` project provides server configurations that can simplify the setup of individual language servers. However, adopting it introduces an additional dependency and a configuration layer that must be evaluated against the project's native-first principles.

Stage 09 — LSP and `lazydev` establishes the initial language-server workflow. The project should distinguish between configuring Neovim's built-in LSP client and adopting a plugin that supplies server-specific configuration.

## Decision

**Defer the adoption of `nvim-lspconfig` until its value can be evaluated during Stage 09.**

Begin with Neovim's native LSP capabilities and determine the minimum configuration required for the project's initial language-server workflow.

Do not install `nvim-lspconfig` merely because it is commonly used in Neovim configurations or appears in plugin collections.

If native configuration proves sufficient for the project's supported language servers, retain the native approach. Adopt `nvim-lspconfig` only if its server configurations provide a demonstrable maintenance, compatibility, or usability advantage.

This decision does not prohibit future adoption. It requires explicit evaluation before the dependency is accepted.

## Alternatives Considered

### 1. Configure language servers using native Neovim APIs

Use Neovim's built-in LSP client and native configuration mechanisms.

**Advantages**
- Minimizes third-party dependencies.
- Keeps the configuration aligned with Neovim's built-in capabilities.
- Makes the project's language-server setup explicit.
- Avoids introducing a plugin solely to supply configuration that can be maintained directly.

**Trade-offs**
- Requires the project to maintain server-specific settings.
- May involve more configuration work as the number of supported servers grows.
- Requires careful attention to API compatibility and configuration changes across supported Neovim versions.

### 2. Adopt `nvim-lspconfig`

Use the plugin's server configurations alongside Neovim's built-in LSP client.

**Advantages**
- Can reduce the amount of server-specific configuration maintained by this project.
- Provides established configurations for many language servers.
- May simplify adding and maintaining support for additional servers.

**Trade-offs**
- Adds a third-party dependency.
- Introduces an external configuration layer that must be understood and maintained.
- Requires compatibility checks against the project's minimum Neovim version.
- May provide limited additional value if the project supports only a small, deliberately selected set of servers.

### 3. Defer broad language-server support

Implement only the initial LSP workflow needed by the project and evaluate additional servers as language support expands.

**Advantages**
- Keeps the initial implementation focused.
- Avoids premature decisions about a broad language-server inventory.
- Allows dependency decisions to follow demonstrated requirements.

**Trade-offs**
- Additional language servers may require further configuration work.
- The project must clearly document which servers are supported and which remain out of scope.

## Evaluation Criteria

Evaluate native configuration against `nvim-lspconfig` using the following criteria:

1. **Required functionality:** Identify the initial language servers and capabilities the project actually intends to support.
2. **Configuration complexity:** Compare the effort required to maintain native server configurations with the effort required to use the plugin.
3. **Compatibility:** Verify that the selected approach works with the minimum supported Neovim version, currently Neovim 0.12 or later.
4. **Maintainability:** Assess the cost of tracking server configuration changes and maintaining project-specific overrides.
5. **Extensibility:** Determine whether adding the project's planned language servers remains straightforward.
6. **Dependency cost:** Consider the additional dependency, its maintenance requirements, and its effect on the project's minimal baseline.
7. **Separation of concerns:** Keep LSP client configuration distinct from language-server installation and external executable management.
8. **Validation:** Ensure that server startup, attachment, diagnostics, and other required capabilities can be tested in a real Neovim session.

## Relationship to lazydev

`lazydev.nvim` is evaluated separately for its Lua development workflow. Its admission does not automatically require adopting `nvim-lspconfig`.

The project should evaluate each dependency according to its own purpose and demonstrated value. Decisions about server configuration must not be inferred from the decision to use a development helper.

## Consequences

Until the evaluation is complete:

- `nvim-lspconfig` is not an approved dependency.
- Stage 09 may proceed with native LSP configuration.
- The initial language-server scope should remain explicit and limited to validated requirements.
- Language-server installation and executable availability remain separate from Neovim's LSP configuration.
- The plugin inventory and dependency documentation must reflect the final decision once made.

If native configuration meets the requirements without excessive maintenance, prefer it. If maintaining server configurations becomes disproportionate to the project's goals, reconsider the plugin using the evaluation criteria above.

## Validation

Before accepting a final approach:

- Confirm that the configuration loads without errors on the minimum supported Neovim version.
- Verify that at least one selected language server starts and attaches successfully.
- Test the required LSP capabilities for the initial scope.
- Confirm that missing server executables or unavailable servers produce understandable behavior.
- Run the project's applicable syntax and smoke checks.
- Document which language servers were actually tested and any known limitations.

Do not treat successful Lua syntax validation alone as proof that the LSP workflow functions correctly.

## Follow-up

Revisit this ADR during **Stage 09 — LSP and `lazydev`**.

Choose one outcome:

- **Accepted:** Adopt `nvim-lspconfig` after demonstrating that its benefits justify the dependency.
- **Rejected:** Retain native LSP configuration because the plugin does not provide sufficient additional value.
- **Deferred:** Keep the decision open if the supported server scope or maintenance requirements are not yet clear.

Update this record, the plugin inventory, and dependency documentation to reflect the final decision. Do not add the plugin to the configuration until it has been explicitly approved.
