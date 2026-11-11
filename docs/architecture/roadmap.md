# Roadmap

## Current Status

- **Stages 01–03:** Complete.
- **Stage 04 — Native Workflows:** In progress. The native commenting workflow remains unresolved.
- **Stages 05–09:** Complete. Stage 09's native LSP and lazydev implementation, including its defined validation, is closed out.
- **Stage 10 — Completion and Snippets:** Implementation is in place. Interactive verification remains in progress.
- **Stage 11 — Format and Lint:** Complete for the defined manual formatting implementation and automated validation. Python's Ruff native LSP lint integration was also implemented and validated as part of the Python language pack.
- **Stage 12 — Git, Root, and Sessions:** In progress. Gitsigns, `DrKJeff16/project.nvim`, and `mini.sessions` are implemented. Interactive checks for Git workflows, project navigation, and session save/restore have passed. Stage 12 smoke-test checks also pass on Neovim 0.12.6. Related documentation, dependency and keymap alignment, and remaining stage-closeout requirements are still outstanding.
- **Stage 13 — Language Packs:** Complete. All 11 core language packs and all 4 additional language integrations are implemented and validated.
- **Stages 14–17:** Planned.

Later-stage work must not be used to imply that an earlier stage's outstanding requirements have been resolved. In particular, Stage 12 does not reopen Stage 09. Stage 13's completed language packs do not close Stage 10 or change the completion status of Stage 11.

> Update this status whenever a stage formally changes. Do not infer completion from the presence of configuration files alone.

---

## Stage 13 — Language Packs

**Status:** Complete.

**Objective:** Extend the configuration for selected programming, markup, and tooling environments while keeping language support modular, dependencies explicit, and tool installation separate from Neovim startup.

### Language support overview

Stage 13 covers 11 core language groups, implemented in the agreed order, and 4 additional integrations.

- **Core baseline:** 11 language groups.
- **Additional integrations:** 4.
- **Total:** 15 completed language and tooling integrations.

### Core language baseline

The Stage 13 core baseline covers these 11 language groups in the following implementation order:

1. Lua
2. Python
3. YAML
4. JSON
5. Shell
6. PowerShell
7. HTML
8. CSS
9. JavaScript/TypeScript
10. Markdown
11. Rust

This is the agreed build order. It determines the sequence of implementation and validation, not merely the order in which languages appear in documentation.

### Core implementation status

| Language group | Classification | Status |
|---|---|---|
| Lua | Core | Complete |
| Python | Core | Complete |
| YAML | Core | Complete |
| JSON | Core | Complete |
| Shell | Core | Complete |
| PowerShell | Core | Complete |
| HTML | Core | Complete |
| CSS | Core | Complete |
| JavaScript/TypeScript | Core | Complete |
| Markdown | Core | Complete |
| Rust | Core | Complete |

HTML and CSS are part of the core baseline. They must not be classified as optional language packs because earlier documentation placed HTML under an optional web pack. The language index and supporting documentation must reflect their core classification.

### Additional integrations

The following integrations are complete but remain separate from the 11-language core baseline.

| Language / Integration | Classification | Status |
|---|---|---|
| C | Additional | Complete |
| C++ | Additional | Complete |
| Docker | Additional | Complete |
| SQL | Additional | Complete |

These integrations extend the configuration without changing the core baseline or its agreed implementation order.

### Scope

- Define and maintain the supported language baseline.
- Implement and maintain language packs in the agreed build order.
- Keep additional integrations separate from the core baseline.
- Document language servers, formatters, linters, parsers, schemas, and other required external tools.
- Keep language-specific configuration modular.
- Reuse the existing native LSP registry and activation architecture from Stage 09.
- Use Conform for approved formatting workflows.
- Keep external executable installation and updates separate from plugin installation.
- Validate language-specific workflows independently.
- Keep core language support distinct from optional and additional integrations.

### Completion criteria

- All 11 core language groups are implemented.
- All 4 additional integrations are implemented.
- Each supported language or integration has clearly defined configuration and responsibility boundaries.
- Language-server configuration uses the established native LSP architecture where applicable.
- Formatting and linting responsibilities are explicit and do not conflict.
- Required external tools are documented and available in the validation environment.
- Parser, language-server, diagnostic, formatting, and other applicable workflows are validated.
- Language-specific configuration passes syntax and formatting checks.
- The language index and supporting documentation reflect the actual implementation.
- The configuration avoids installing unrelated tools by default.
- Additional integrations remain separate from the core language baseline.

### Implementation boundaries

- Stage 13 does not reopen Stage 09's completed LSP foundation.
- Stage 13 does not reopen Stage 10's completion and snippet implementation.
- Language-specific lint integration may be implemented within an individual language pack without implying that every language uses the same linting workflow.
- Formatting remains manual by default. Do not introduce format-on-save or LSP formatting fallback without a separate decision.
- Do not introduce Mason or Neovim-side external-tool installation.
- Keep external executable installation and updates separate from Neovim plugin installation.
- Changes to completion mappings or Blink configuration remain within Stage 10.
- Additional integrations must not change the agreed 11-language core baseline.

Stage 13 is complete. All 11 core language groups and all 4 additional integrations are implemented and validated.

---

## Stage 14 — Development Workflows

**Status:** Planned.

**Objective:** Extend the configuration with additional development workflows while preserving modular plugin ownership, explicit dependencies, and native Neovim integration.

Implementation scope and completion criteria will be defined before work begins.

## Stage 15 — Debugging

**Status:** Planned.

**Objective:** Introduce a modular debugging environment with explicit debugger dependencies and language-specific configuration.

Implementation scope and completion criteria will be defined before work begins.

## Stage 16 — Performance and Lazy Loading

**Status:** Planned.

**Objective:** Evaluate startup performance and introduce lazy loading only after the existing eager-loading configuration has been validated.

Lazy loading must be evidence-driven and must preserve deterministic plugin behavior.

Implementation scope and completion criteria will be defined before work begins.

## Stage 17 — Final Integration and Release

**Status:** Planned.

**Objective:** Complete final integration, documentation, regression testing, and release preparation.

Implementation scope and completion criteria will be defined before work begins.

---

## Roadmap Maintenance Rules

- Update stage status only when its defined implementation and validation requirements are satisfied.
- Keep implementation completion distinct from formal stage closeout when documentation or other closeout requirements remain.
- Do not infer completion from configuration files, plugin installation, or successful startup alone.
- Keep stage ownership clear. Work in one stage must not silently change another stage's completion status.
- Preserve agreed architecture and implementation decisions unless a separate decision explicitly changes them.
- Update supporting documentation and validation records when implementation changes.
- Keep planned stages separate from active implementation work.
