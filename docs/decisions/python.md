## Decision

**Status: Accepted direction; implementation pending validation and applicable stage gates.**

The Python workflow adopts the following tooling decisions:

| Capability | Decision | Status |
|---|---|---|
| Language server | Astral `ty` | Accepted; evaluate first |
| Code formatting | Ruff (`ruff format`) through Conform | Accepted |
| CLI linting | Ruff (`ruff check`) | Accepted; independent command-line workflow |
| Editor linting | Ruff through a Neovim editor integration | Accepted; integration selection and admission review required |
| Syntax parsing | Existing Tree-sitter integration | Reuse; verify Python parser support |

### Language server: `ty`

Evaluate `ty` as the first Python language-server implementation. Verify compatibility with the supported Neovim version, maintained server definitions, executable discovery, project-root detection, Python environment discovery, and required LSP capabilities before activation.

BasedPyright and Pyright remain alternatives only if evaluation identifies a material gap.

### Formatter: Ruff

Use Ruff's formatter through the existing Conform integration. The formatter must follow the established manual-formatting workflow. Do not enable format-on-save or introduce LSP formatting as an undocumented fallback.

### CLI linter: Ruff

Use `ruff check` for independent command-line linting. Document the executable and its prerequisites separately from Neovim plugin dependencies.

### Editor linting: Ruff integration

Integrate Ruff diagnostics into Neovim through a separately evaluated editor-linting integration.

Before implementation, complete the applicable Stage 11 admission review. The review must document the selected integration, its justification, alternatives considered, dependency and compatibility impact, interaction with Conform, and acceptance tests.

The implementation must:

- Verify that Ruff's executable is available.
- Report missing dependencies without installing tools automatically.
- Use a dedicated diagnostic namespace.
- Verify stale-diagnostic cleanup when buffers change, linting reruns, or results become invalid.
- Avoid unnecessary duplication between Ruff diagnostics and language-server diagnostics.
- Define when linting runs and how its results are updated.
- Preserve the existing formatting workflow and centralized configuration architecture.

Accepting editor linting as a Python capability does not approve a particular plugin or authorize bypassing the Stage 11 admission review.

### Installation and validation

These decisions establish the intended tooling direction. They do not establish that any executable is installed, that a plugin has been admitted, or that the implementation has passed validation.

Update the dependency inventory, plugin inventory, and roadmap only as the corresponding decisions and implementation steps are completed.
