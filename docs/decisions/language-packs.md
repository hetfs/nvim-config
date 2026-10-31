# Stage 13 — Language Packs: Design Decision

- **Status:** Accepted — design direction only; implementation is gated
- **Date:** 2026-10-27
- **Scope:** Language-server configuration, formatting, language-pack architecture, and external dependency planning
- **Implementation status:** Not started
- **Plugin admission:** No new plugins approved

## 1. Context

Stage 13 extends the existing language-pack architecture to support the project's approved language baseline while preserving its native-first principles.

The architecture already provides the following responsibilities:

- Neovim's native `vim.lsp.config()` and `vim.lsp.enable()` APIs for language-server configuration and activation.
- The existing `nvim-lspconfig` installation for maintained language-server definitions where applicable.
- The project-local `lua/langs/` registry for deterministic language-pack discovery and aggregation of language-specific metadata.
- `lua/config/lsp.lua` for shared LSP lifecycle behavior.
- `lua/config/keymaps.lua` for centralized user-facing keymaps.
- Conform.nvim as the existing formatting integration.
- External tools managed independently of Neovim plugin installation.

Stage 13 must extend these responsibilities without duplicating shared infrastructure, introducing another LSP framework, or treating proposed dependencies as installed capabilities.

The design must also distinguish three separate concerns:

1. **Neovim integration:** Configuration, activation, formatting, and diagnostic behavior.
2. **External dependencies:** Language servers, formatters, linters, parsers, and supporting runtimes.
3. **Language-pack validation:** Repeatable checks that establish whether each configuration works as intended.

A language pack is not complete merely because its configuration loads or its executable is installed.

## 2. Decision

### 2.1 Language baseline and build order

The Stage 13 evaluation baseline covers these 11 language groups in the following implementation order:

1. Lua
2. Python
3. YAML
4. JSON
5. Shell scripting
6. PowerShell
7. HTML
8. CSS
9. JavaScript and TypeScript
10. Markdown
11. Rust

This sequence defines the preferred build and validation order for Stage 13. Language packs should be implemented in this order, subject to the earlier-stage closeout gates and the dependency decisions for each language.

The build order is not a dependency-priority ranking. It does not establish that every language server, formatter, linter, parser, or external executable has been selected, installed, or validated.

Language-specific implementation details must remain in their respective language-pack modules and documentation. This design decision defines shared architectural boundaries rather than replacing those documents.

### 2.2 Dependency selection policy

The language-server and tool matrix below records proposed candidates for evaluation. A candidate is not an approved installation instruction.

Before admitting a candidate, verify:

- The current server identifier and configuration contract.
- Supported filetypes and relevant language features.
- Required executable names and installation methods.
- Runtime and platform requirements.
- Compatibility with the installed Neovim version and `nvim-lspconfig` definitions, where applicable.
- Integration with the existing language registry, formatter configuration, and root-detection behavior.
- Repeatable validation procedures.

The final selection for each language must be documented in its language-specific support document before implementation is considered complete.

## 3. Proposed language and dependency matrix

The matrix follows the preferred Stage 13 build order. All entries are evaluation candidates, not approved installation instructions.

| Build order | Language group | Language-server candidate | Formatter candidate | Additional CLI tooling |
|---:|---|---|---|---|
| 1 | Lua | `lua_ls` | StyLua | None selected |
| 2 | Python | Astral `ty` | Ruff (`ruff format`) | Ruff (`ruff check`) |
| 3 | YAML | `yamlls` | Prettier | Native LSP diagnostics initially |
| 4 | JSON | `jsonls` | Prettier | Native LSP diagnostics initially |
| 5 | Shell scripting | `bashls` | `shfmt` | ShellCheck evaluation candidate |
| 6 | PowerShell | PowerShell Editor Services (PSES) | LSP-provided formatting through PSES | PSScriptAnalyzer |
| 7 | HTML | `html` | Prettier | Native LSP diagnostics initially |
| 8 | CSS | `cssls` | Prettier | Native LSP diagnostics initially |
| 9 | JavaScript / TypeScript | `ts_ls` | Prettier | Defer lint-tool selection |
| 10 | Markdown | Marksman | Prettier | No standalone lint integration selected |
| 11 | Rust | `rust-analyzer` | `rustfmt` | Cargo |

**Important distinctions:**

- `ty` is an evaluation candidate for Python language-server functionality. Its capabilities and compatibility with the intended Python workflow must be verified before adoption.
- Ruff provides Python formatting and linting capabilities. It does not replace the language server.
- PowerShell formatting uses the existing PSES-based approach under evaluation. Do not assume that a standalone formatter executable exists or introduce one without evidence.
- Native LSP diagnostics are not equivalent to standalone CLI linting.
- A formatter candidate does not imply that format-on-save is enabled.
- The matrix does not authorize installing additional plugins or automatically installing external tools.

The language-specific documents remain the authoritative sources for final server, formatter, and dependency decisions.

## 4. Architecture and responsibility boundaries

### 4.1 Language packs

Language-specific modules under `lua/langs/` own language-specific configuration and metadata.

Where applicable, a language pack may declare:

- Language-server configuration and activation.
- Supported filetypes.
- Formatter metadata consumed by the existing registry.
- Language-specific prerequisites.
- Language-specific commands or editing workflows where separately justified.
- Validation requirements and expected behavior.

The existing registry remains responsible for deterministic discovery and metadata aggregation.

Stage 13 must not introduce a second registry, duplicate language-pack setup paths, or create another mechanism for discovering language-specific configuration.

Each language pack must follow the existing module conventions and keep its configuration separate from unrelated language packs.

### 4.2 Shared LSP infrastructure

The existing native LSP configuration and shared lifecycle behavior remain in place.

Language packs must not duplicate common attachment behavior, redefine centralized keymaps unnecessarily, or introduce another LSP framework.

Server configuration should reuse maintained `nvim-lspconfig` definitions where appropriate while preserving Neovim's native LSP APIs.

Language-specific behavior belongs in the relevant pack. Shared lifecycle behavior belongs in `lua/config/lsp.lua`.

Any proposed change to these boundaries requires a demonstrated technical need and a separate review.

### 4.3 Formatting

Conform.nvim remains the sole formatting integration.

Language packs may declare formatter defaults, while existing user preferences continue to be resolved through:

- `lua/config/format.lua`
- `lua/config/languages.lua`

Formatter selection must remain explicit and consistent with the existing registry contract.

Formatting behavior must be validated independently of language-server startup. The presence of a language server must not be treated as proof that formatting works.

Format-on-save remains disabled by default unless a separate accepted decision changes that policy.

### 4.4 Linting

The Neovim linting-integration decision remains unresolved.

Before selecting an integration, review Stage 11's existing scope, implementation, candidate policy, executable requirements, filetype coverage, diagnostic overlap, and validation requirements.

Stage 13 must not introduce a linting integration plugin or another linting framework.

Installing a standalone CLI linter does not authorize integrating it into Neovim. Likewise, the existence of LSP diagnostics does not establish that standalone linting requirements have been satisfied.

The selected approach must document which tool produces each diagnostic, how it is invoked, and how overlapping diagnostics will be avoided.

### 4.5 Project roots and working directories

Reuse the existing project.nvim direction and root-detection architecture.

Do not introduce another project-root plugin or a new root abstraction without a demonstrated requirement and a separately reviewed decision.

Language-server root markers must be evaluated against representative repositories and the current project behavior.

Root detection must remain distinct from changing Neovim's working directory. Attaching a language server to a project must not implicitly change the user's working directory unless a separately accepted decision explicitly requires that behavior.

### 4.6 Tree-sitter

Reuse the existing Tree-sitter integration.

Evaluate additional parser requirements only where they provide a defined benefit to the selected language baseline.

Parser availability, compiler prerequisites, highlighting behavior, language-server installation, and formatter installation are separate concerns. Passing one validation does not establish that the others work.

## 5. External dependency policy

Language servers, formatters, linters, parsers, and supporting runtimes are external dependencies unless explicitly documented otherwise.

The project will:

- Keep external executable installation separate from Neovim plugin installation.
- Avoid installing tools automatically during Neovim startup.
- Keep tool installation scripts and dependency manifests separate from language-pack configuration.
- Document executable names, installation methods, runtime requirements, and verification commands.
- Avoid adding a package manager or tool-installation plugin solely to simplify language setup.
- Verify external tool availability independently of plugin configuration.
- Document platform-specific limitations and supported installation methods.
- Avoid adding a dependency when an existing tool adequately satisfies the requirement.
- Distinguish required dependencies from optional tools.
- Ensure dependency checks report missing tools clearly without silently installing them.

Where installation scripts are provided, they must follow the project's existing dependency-management conventions and remain independently testable.

The language-pack configuration must not assume that an executable is available merely because its name appears in a manifest or documentation file.

## 6. Language-pack validation requirements

Every admitted language must be validated against representative files and repositories.

Validation must cover the following areas.

| Area | Required verification |
|---|---|
| Filetype detection | Representative files receive the expected Neovim filetypes. |
| Server configuration | The server configuration is valid and compatible with the installed Neovim version. |
| Server attachment | The intended server starts and attaches to the correct buffers. |
| Language features | Relevant diagnostics and language features behave as expected. |
| Formatting | The intended formatter is selected and produces valid, expected output. |
| External dependencies | Required executables and supporting runtimes are available and correctly identified. |
| Root detection | Representative repositories produce the expected project roots without unintended working-directory changes. |
| Keymaps | Existing centralized mappings continue to work without unnecessary duplication or conflicts. |
| Tree-sitter | Required parsers are available and provide the expected highlighting behavior. |
| Documentation | Installation, prerequisites, configuration, and verification instructions match the implementation. |
| Regression checks | Existing language packs and shared configuration continue to pass their established checks. |

Not every language requires every optional capability. Any omitted capability must be intentional and documented rather than assumed to work.

### 6.1 Automated validation

Headless smoke tests should validate the contracts that can be tested reliably without an interactive session, including:

- Language-pack discovery and metadata aggregation.
- Configuration loading and registration.
- Expected filetype and formatter mappings.
- Missing-dependency handling.
- Failure behavior and regression protection.
- Relevant syntax and configuration checks.

Tests must not require network access or install external dependencies as a side effect.

### 6.2 Interactive validation

Headless tests do not replace interactive verification of actual language-server attachment or editing behavior.

For each language, perform the applicable interactive checks, including:

- Opening representative files and confirming the intended server attaches.
- Confirming diagnostics and relevant language features.
- Invoking formatting and inspecting the resulting changes.
- Verifying project-root behavior in representative repositories.
- Confirming that existing keymaps and shared workflows remain functional.

A language pack must not be marked complete solely because its module loads or its smoke tests pass.

## 7. Implementation gates

Stage 13 implementation must not bypass outstanding requirements from earlier stages.

Before implementation begins, preserve and address the applicable closeout requirements.

### Stage 04 — Native workflows

- Resolve the outstanding native commenting workflow.
- Verify the actual `gc` and `gcc` behavior before documenting those mappings as implemented.
- Align the documentation with verified behavior.

### Stage 10 — Completion and snippets

- Complete interactive verification of completion behavior.
- Verify snippet expansion and placeholder navigation.
- Verify the expected pairing behavior.
- Document any remaining limitations before closeout.

### Stage 12 — Git, roots, and sessions

- Complete outstanding documentation.
- Align dependency and keymap documentation with the implementation.
- Complete the required stage-closeout checks.

Planning, documenting, or evaluating Stage 13 does not declare any earlier stage complete.

The implementation gate is satisfied only when the applicable earlier-stage requirements have been addressed and their status is supported by verification evidence.

## 8. Implementation and acceptance criteria

Stage 13 implementation may proceed only within the accepted architecture and the dependency decisions established for each language.

The preferred implementation sequence is the order defined in Section 2.1 and reflected in Section 3.

A language pack is eligible for acceptance when:

1. Its configuration follows the existing registry and module conventions.
2. Its language-server configuration uses the existing native LSP architecture.
3. Its formatter configuration uses Conform.nvim and the existing formatter-preference mechanism.
4. Required external dependencies and optional tools are documented separately.
5. Missing dependencies produce clear, actionable feedback.
6. Automated checks pass for the relevant configuration contracts.
7. Interactive validation confirms the applicable language features and editing workflows.
8. Existing shared configuration and previously accepted language packs remain functional.
9. Documentation reflects the implemented behavior and provides repeatable verification steps.

The Stage 13 implementation must not be considered complete until the applicable language packs satisfy these criteria and the required evidence has been reviewed.

## 9. Explicit non-goals

This decision does not authorize:

- A new LSP framework or a replacement for Neovim's native LSP APIs.
- A second language registry or duplicate language-pack setup paths.
- New plugins for linting, dependency installation, or project-root detection.
- Automatic external tool installation during Neovim startup.
- Enabling format-on-save by default.
- Treating proposed dependencies as installed or validated capabilities.
- Declaring earlier stages complete without their required verification.
- Expanding the language baseline without a documented and reviewed scope decision.

## 10. Decision summary

Stage 13 extends the existing language-pack architecture without replacing its shared infrastructure.

Language-specific configuration remains modular. Shared LSP lifecycle behavior, formatter preferences, keymaps, project-root behavior, and Tree-sitter integration remain centralized in their existing components.

The preferred build order is Lua, Python, YAML, JSON, Shell scripting, PowerShell, HTML, CSS, JavaScript and TypeScript, Markdown, and Rust.

External tools are managed separately from Neovim plugins. Candidate selection requires explicit evaluation, and implementation requires repeatable automated checks and applicable interactive verification.

**Accepted:** Architectural direction, responsibility boundaries, dependency policy, preferred build order, and implementation gates.

**Not yet approved:** Individual candidate dependencies that have not completed evaluation, new plugin admissions, and implementation changes.

**Current status:** Design accepted. Implementation not started. Earlier-stage closeout requirements remain in force.
