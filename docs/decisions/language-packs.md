
# Stage 13 — Language Packs: Design Decision

- **Status:** Accepted — design direction only; implementation is gated
- **Date:** 2026-10-27
- **Scope:** Language-server evaluation, formatting, language profiles, and external dependency planning
- **Implementation status:** Not started
- **Plugin admission:** No new plugins approved

## 1. Context

Stage 13 extends the existing language-pack architecture to cover a broader baseline of programming and configuration languages while preserving the project's native-first principles.

The existing architecture uses:

- Neovim's native `vim.lsp.config()` and `vim.lsp.enable()` APIs.
- The existing `nvim-lspconfig` installation for maintained language-server definitions where applicable.
- The project-local `lua/langs/` registry for deterministic language-pack discovery and aggregation of language-specific metadata.
- `lua/config/lsp.lua` for shared LSP lifecycle behavior.
- `lua/config/keymaps.lua` for centralized user-facing mappings.
- Conform.nvim as the existing formatting integration.
- External tools managed separately from Neovim plugins.

Stage 13 must extend these responsibilities without duplicating shared infrastructure, introducing a second LSP framework, or treating proposed dependencies as installed capabilities.

## 2. Decision

### 2.1 Supported language baseline

The design covers these language groups:

1. lua
2. Python
3. JavaScript
4. TypeScript
5. JSON
6. YAML
7. Shell scripting
8. Rust
9. Powershell
10. HTML
12. CSS
13. Markdown

This is the target scope for evaluation, not a claim that every language server, formatter, parser, or external executable has been selected or validated.


## 2. Proposed language and dependency matrix

All server and tool names in this matrix are **evaluation candidates**, not approved installation instructions.

| Language group | Language-server candidate | Formatter candidate | Additional CLI tooling |
|---|---|---|---|
| Python | Astral `ty` | Ruff (`ruff format`) | Ruff (`ruff check`) |
| JavaScript / TypeScript | `ts_ls` | Prettier | Defer lint-tool selection |
| JSON | `jsonls` | Prettier | Native LSP diagnostics initially |
| YAML | `yamlls` | Prettier | Native LSP diagnostics initially |
| Shell | `bashls` | `shfmt` | ShellCheck evaluation candidate |
| HTML | `html` | Prettier | Native LSP diagnostics initially |
| CSS | `cssls` | Prettier | Native LSP diagnostics initially |
| Markdown | Marksman | Prettier | No standalone lint integration selected |

Before accepting any candidate, verify its current server identifier, supported filetypes, executable name, installation requirements, configuration contract, and compatibility with the installed `nvim-lspconfig` definitions.

The matrix intentionally does not select a universal linter. Native LSP diagnostics and standalone CLI linting are different mechanisms and must not be presented as equivalent.

## 3. Architecture and responsibility boundaries

### Language packs

Language-specific modules under `lua/langs/` own language-specific configuration and metadata.

Where applicable, a language pack may declare:

- Language-server configuration and activation.
- Formatter metadata consumed by the existing registry.
- Supported filetypes.
- Language-specific prerequisites and validation requirements.

The existing registry remains responsible for deterministic discovery and metadata aggregation. Stage 13 must not introduce a second registry or duplicate setup paths.

### Shared LSP infrastructure

The existing native LSP configuration and shared lifecycle behavior remain in place.

Language packs must not duplicate common attachment behavior or redefine centralized keymaps unnecessarily. Server configuration should reuse maintained `nvim-lspconfig` definitions where appropriate and preserve Neovim's native LSP API.

### Formatting

Conform.nvim remains the sole formatting integration.

Language packs may declare formatter defaults, while existing user preferences continue to be resolved through `lua/config/format.lua` and `lua/config/languages.lua`.

Formatting behavior must remain explicit. Format-on-save stays disabled by default unless a separate decision changes that policy.

### Linting

The Neovim linting-integration decision remains unresolved.

Before selecting any integration, review Stage 11's existing scope, implementation, candidate policy, executable requirements, filetype coverage, diagnostic overlap, and validation requirements.

Do not introduce a linting integration plugin as part of Stage 13. A proposed CLI tool does not authorize a Neovim integration.

### Project roots and working directories

Reuse the existing project.nvim direction and root-detection architecture. Do not introduce another project-root plugin or a new root abstraction without a demonstrated requirement and a separately reviewed decision.

Language-server root markers must be evaluated against representative repositories and the current project behavior. Root detection must not be conflated with automatically changing Neovim's working directory.

### Tree-sitter

Reuse the existing Tree-sitter integration. Evaluate additional parser requirements only where they provide a defined benefit to the selected language baseline.

Parser availability, compiler prerequisites, and highlighting behavior remain separate from language-server and formatter installation.

## 4. External dependency policy

Language servers, formatters, linters, parsers, and their supporting runtimes are external dependencies unless explicitly documented otherwise.

The project will:

- Keep external executable installation separate from Neovim plugin installation.
- Avoid installing tools automatically during Neovim startup.
- Document executable names, installation options, and verification commands.
- Avoid adding a package manager or tool-installation plugin solely to simplify language setup.
- Verify external tool availability independently of plugin configuration.
- Document platform-specific limitations where relevant.
- Avoid requiring a new dependency when an existing tool adequately satisfies the requirement.

### Other language groups

For each admitted language, validate the selected server and formatter against representative files, including:

- Filetype detection.
- Server startup and attachment.
- Relevant diagnostics and language features.
- Formatter selection and output.
- External executable availability.
- Compatibility with existing keymaps, root detection, and shared configuration.
- Documentation and repeatable checks.

Headless smoke tests can validate configuration contracts and registration. They do not replace interactive verification of actual language-server attachment or editing behavior.

## 5. Earlier-stage closeout gate

This decision does not bypass outstanding requirements in earlier stages.

Before Stage 13 implementation begins, preserve and address the applicable closeout requirements, including:

- **Stage 04:** Resolve the outstanding native commenting workflow and align documentation with verified behavior.
- **Stage 10:** Complete the required interactive verification of completion, snippets, placeholder navigation, and pairing behavior.
- **Stage 12:** Complete outstanding documentation, dependency and keymap alignment, and required stage-closeout checks.
Planning and documenting Stage 13 does not declare any earlier stage complete.
