# Roadmap

## Table of Contents

- [Current Status](#current-status)
- [Stage Governance](#stage-governance)
- [Stage 13 — Language Packs](#stage-13--language-packs)
  - [Objective](#objective)
  - [Language Support Overview](#language-support-overview)
  - [Core Language Baseline](#core-language-baseline)
  - [Additional Integrations](#additional-integrations)
  - [Future Language Support](#future-language-support)
  - [Scope](#scope)
  - [Completion Criteria](#completion-criteria)
  - [Implementation Boundaries](#implementation-boundaries)
  - [Stage Closeout](#stage-closeout)
- [Stage 14 — Debugging (DAP)](#stage-14--debugging-dap)
  - [Objective](#objective-1)
  - [Candidate Components](#candidate-components)
  - [Language Coverage](#language-coverage)
  - [Scope](#scope-1)
  - [Implementation Boundaries](#implementation-boundaries-1)
  - [Completion Criteria](#completion-criteria-1)
  - [Stage Closeout](#stage-closeout-1)
- [Stage 15 — Development Workflows](#stage-15--development-workflows)
  - [Objective](#objective-2)
  - [Selected Integration](#selected-integration)
  - [Scope](#scope-2)
  - [Implementation Boundaries](#implementation-boundaries-2)
  - [Completion Criteria](#completion-criteria-2)
  - [Stage Closeout](#stage-closeout-2)

---

## Current Status

The project follows a 31-stage implementation roadmap. Implementation progress, validation results, and formal stage acceptance are tracked independently.

### Completed stages

- **Stages 01–03:** Complete.
- **Stages 05–09:** Complete. Stage 09, including the native LSP and LazyDev implementation and its defined validation, is formally closed.
- **Stage 11 — Format and Lint:** Complete. The defined manual formatting workflows and automated validation have passed. Python's Ruff native LSP lint integration was also implemented and validated as part of the Python language pack.
- **Stage 13 — Language Packs:** Complete. All 13 core language groups and 5 additional integrations have been implemented and validated.
- **Stages 21–22:** Complete. Acceptance tests have passed.
- **Stages 27–28:** Complete. Acceptance tests have passed.

### In-progress stages

- **Stage 04 — Native Workflows:** In progress. The native commenting workflow remains unresolved. The stage must remain open until all outstanding requirements are implemented and validated.
- **Stage 10 — Completion and Snippets:** Implementation complete; interactive verification in progress. Completion, snippet expansion, and related behavior must be verified before formal closeout.
- **Stage 12 — Git, Root, and Sessions:** In progress. Gitsigns, `project.nvim`, and `mini.sessions` are implemented. Interactive validation of Git workflows, project navigation, and session save/restore has passed. Stage 12 smoke tests also pass on Neovim 0.12.6. Documentation, dependency and keymap alignment, and remaining closeout requirements are outstanding.
- **Stage 15 — Development Workflows:** CodeCompanion configuration work is complete. Formal acceptance remains pending.

### Planned and reserved stages

- **Stage 14 — Debugging (DAP):** Planned. The objective is to integrate DAP for applicable languages and runtimes supported by Stage 13. Implementation has not started.
- **Stage 16:** Reserved. Scope has not been defined.
- **Stages 29–31:** Planned.

### Implemented stages awaiting acceptance

- **Stages 17–20:** Implemented; behavioral or runtime acceptance remains outstanding.
- **Stages 23–26:** Implemented; behavioral or visual acceptance remains outstanding.

### Status summary

| Stage | Scope | Status |
|---|---|---|
| 01–03 | Foundation and modular configuration | Complete |
| 04 | Native Workflows | In progress |
| 05–09 | Plugin management, discovery, navigation, Tree-sitter, and LSP | Complete |
| 10 | Completion and Snippets | Implementation complete; verification in progress |
| 11 | Format and Lint | Complete |
| 12 | Git, Root, and Sessions | In progress |
| 13 | Language Packs | Complete |
| 14 | Debugging (DAP) | Planned |
| 15 | Development Workflows | Configuration complete; acceptance pending |
| 16 | Reserved | Scope undefined |
| 17–20 | Later roadmap stages | Implemented; acceptance outstanding |
| 21–22 | Later roadmap stages | Complete |
| 23–26 | Later roadmap stages | Implemented; acceptance outstanding |
| 27–28 | Later roadmap stages | Complete |
| 29–31 | Later roadmap stages | Planned |

---

## Stage Governance

Stage completion is determined by its defined implementation, validation, and formal closeout requirements.

Progress in later stages must not be used to imply that outstanding requirements in earlier stages have been resolved.

### Status and dependency rules

- Completing Stage 12 does not reopen or change the completion status of Stage 09.
- Completing Stage 13 does not close Stage 10 or resolve its outstanding verification requirements.
- Stage 13 does not change the completion status of Stage 11.
- Additional language-specific integrations do not change the established core language baseline.
- Future language candidates do not count toward completed core or additional integrations.
- Configuration files or successful startup alone do not establish stage completion.
- Plugin admission does not establish successful installation or behavioral acceptance.
- Keymap registration does not establish that the associated workflow operates correctly.
- Passing tests in a later stage does not automatically satisfy the acceptance criteria of an earlier stage.

### Stage maintenance

Update this roadmap whenever a stage formally changes status.

Every stage must maintain a clear distinction between:

1. **Implementation:** The required configuration and functionality exist.
2. **Validation:** The defined automated and interactive checks have passed.
3. **Formal closeout:** All stage requirements and acceptance criteria have been satisfied.

Do not mark a stage complete solely because its configuration loads or its implementation appears functional.

---

# Stage 13 — Language Packs

<badge color="success">Complete</badge>

## Objective

Extend the configuration to support selected programming languages, markup formats, and development tooling environments while maintaining modular language support, explicit dependencies, and a clear separation between Neovim configuration and external tool installation.

## Language Support Overview

Stage 13 covers 13 core language groups and 5 additional integrations.

| Classification | Count |
|---|---:|
| Core language groups | 13 |
| Additional integrations | 5 |
| **Total implemented integrations** | **18** |

Four additional languages are identified as future candidates. They are not included in the current implementation count or Stage 13 completion criteria.

## Core Language Baseline

The core baseline consists of the following 13 language groups.

### Core language inventory

| Language Group | Classification | Status |
|---|---|---|
| C | Core | Complete |
| CSS | Core | Complete |
| HTML | Core | Complete |
| JavaScript/TypeScript | Core | Complete |
| JSON | Core | Complete |
| Lua | Core | Complete |
| Markdown | Core | Complete |
| PowerShell | Core | Complete |
| Python | Core | Complete |
| Rust | Core | Complete |
| Shell | Core | Complete |
| TOML | Core | Complete |
| YAML | Core | Complete |

### Baseline requirements

- C is classified as a core language group, not an additional integration.
- CSS and HTML are core language groups, not optional integrations.
- Rust is part of the core baseline.
- TOML is part of the core baseline and must appear in the language index and supporting documentation.
- The original 11-language implementation order remains unchanged.
- TOML and C are additional completed core entries and do not alter the agreed implementation order of the original 11 language groups.

The alphabetical presentation above is for documentation consistency. It does not redefine the historical implementation sequence.

## Additional Integrations

The following five integrations extend the configuration without changing the core language baseline.

| Language / Integration | Classification | Status |
|---|---|---|
| C++ | Additional | Complete |
| Docker | Additional | Complete |
| Go | Additional | Complete |
| MDX | Additional | Complete |
| SQL | Additional | Complete |

### Classification requirements

- C++ remains separate from C.
- Reclassifying C as a core language does not automatically change the classification of C++.
- MDX remains an additional integration alongside Markdown.
- Go remains an additional integration and does not change the core language baseline.
- Additional integrations retain their established implementation order and independent classification.

## Future Language Support

The following languages are identified as potential future additions.

| Language | Classification | Status |
|---|---|---|
| Java | Future | Planned |
| Kotlin | Future | Planned |
| Swift | Future | Planned |
| Zig | Future | Planned |

These languages are not part of the current Stage 13 implementation scope.

### Admission requirements

Each candidate requires a separate evaluation covering:

- Configuration ownership and modularity.
- External executable dependencies.
- Formatters and linters.
- Language-server support.
- Platform compatibility.
- Runtime and tooling requirements.
- Tree-sitter parser availability.
- Validation and acceptance criteria.

Future language candidates must not be counted as implemented core language groups or additional integrations until their implementation is approved and validated.

## Scope

Stage 13 covers the following responsibilities:

- Maintain the established 13-language core baseline.
- Maintain the 5 additional integrations separately from the core baseline.
- Track future language candidates independently.
- Preserve the agreed implementation order.
- Document language servers, formatters, linters, parsers, schemas, and required external tools.
- Keep language-specific configuration modular and independently maintainable.
- Reuse the native LSP registry and activation architecture established in Stage 09.
- Use Conform for approved formatting workflows.
- Keep external executable installation and updates separate from Neovim plugin installation.
- Validate language-specific workflows independently.
- Maintain Markdown and MDX as distinct but related integrations.
- Preserve the classification distinction between C and C++.

## Completion Criteria

Stage 13 is considered complete when the following requirements are satisfied:

- [x] All 13 core language groups are implemented.
- [x] All 5 additional integrations are implemented.
- [x] Each language or integration has clearly defined configuration and responsibility boundaries.
- [x] Language-server configuration uses the established native LSP architecture where applicable.
- [x] Formatting and linting responsibilities are explicitly defined and do not conflict.
- [x] Required external tools are documented and available in the validation environment.
- [x] Applicable parser, language-server, diagnostic, formatting, and other language-specific workflows are validated.
- [x] Language-specific configuration passes syntax and formatting checks.
- [x] The language index and supporting documentation reflect the actual implementation.
- [x] The configuration avoids installing unrelated tools by default.
- [x] Additional integrations remain separate from the core language baseline.
- [x] Future language candidates remain outside the completed implementation count until formally admitted.

## Implementation Boundaries

The following boundaries preserve the architecture and prevent unrelated stages from being reopened:

- Stage 13 does not reopen the completed Stage 09 LSP foundation.
- Stage 13 does not reopen Stage 10's completion and snippet implementation.
- Language-specific lint integration may be implemented within an individual language pack. Every language does not need to use the same linting workflow.
- Formatting remains manual by default. Do not introduce format-on-save or LSP formatting fallback without a separate architectural decision.
- Do not introduce Mason or Neovim-side external tool installation.
- Keep external executable installation and updates separate from Neovim plugin installation.
- Changes to completion mappings or Blink configuration belong to Stage 10.
- Additional integrations must not modify the core language baseline.
- C is a core language group.
- C++ remains an additional integration.
- MDX remains an additional integration, not a core language group.
- Zig, Kotlin, Swift, and Java remain future language candidates until separately approved and implemented.

## Stage Closeout

**Stage 13 is complete.**

All 13 core language groups and all 5 additional integrations have been implemented and validated.

The four future language candidates are tracked separately and do not affect the completed status of Stage 13.

---

# Stage 14 — Debugging (DAP)

<badge color="secondary">Planned</badge>

**Implementation status:** Not started.

## Objective

Integrate the Debug Adapter Protocol (DAP) into the existing Neovim configuration for applicable languages and runtimes supported by Stage 13.

The implementation must provide a modular debugging architecture without coupling debugger configuration to language-server configuration or introducing unnecessary dependencies.

## Candidate Components

The following components are candidates for evaluation, not approved installation requirements.

| Component | Intended Role | Status |
|---|---|---|
| Debug adapters | Connect Neovim to language runtimes and debuggers | Selection pending |
| Debug executables | Provide actual debugging capabilities | External dependencies |
| `nvim-dap` | Debug Adapter Protocol client | Candidate |
| `nvim-dap-ui` | Debugging interface | Candidate |

## Language Coverage

DAP support must be evaluated against the established Stage 13 core baseline and additional integrations.

The following table identifies potential debugger integrations for evaluation.

| Language / Integration | Candidate Debugger | Classification |
|---|---|---|
| C | CodeLLDB or LLDB | Core |
| C++ | CodeLLDB or LLDB | Additional |
| Go | Delve | Additional |
| JavaScript/TypeScript | `vscode-js-debug` | Core |
| Lua | Lua debugger | Core |
| PowerShell | PowerShell Editor Services | Core |
| Python | `debugpy` | Core |
| Rust | CodeLLDB or LLDB | Core |
| Shell | Bash debugger | Core |

This is a candidate compatibility inventory, not an approved installation list.

Actual debugger selection must consider:

- External dependencies.
- Maintenance status.
- Platform compatibility.
- Runtime support.
- Integration complexity.

YAML, JSON, Markdown, TOML, HTML, CSS, Docker, SQL, and MDX do not automatically require dedicated DAP adapters.

Debugging support should be introduced only where an actual runtime or executable debugging requirement exists.

Future language candidates are outside the current Stage 14 language coverage. Their debugging requirements may be evaluated separately if they are admitted into the supported language baseline.

## Scope

Stage 14 covers the following responsibilities:

- Establish DAP architecture and component ownership boundaries.
- Evaluate and select `nvim-dap`.
- Evaluate whether `nvim-dap-ui` provides sufficient value to justify its inclusion.
- Identify and select supported debugger adapters.
- Integrate language-specific debugger configurations.
- Document external debugger executables, runtime requirements, and platform dependencies.
- Define project-owned debugging keymaps.
- Validate launch, attach, breakpoints, stepping, variable inspection, and termination workflows.
- Preserve existing LSP, completion, formatting, and language-pack behavior.

## Implementation Boundaries

- Keep DAP configuration separate from LSP configuration.
- Do not assume that every supported language requires a debugger.
- Keep language-specific adapter configuration modular.
- Do not introduce Mason or silent debugger installation.
- Keep debugger executables separate from Neovim plugin installation.
- Avoid unnecessary modifications to existing language packs.
- Avoid introducing duplicate debugging interfaces.
- Plugin loading alone does not establish working debugging capabilities.

## Completion Criteria

Stage 14 must satisfy the following requirements before formal closeout:

- [ ] DAP architecture and ownership boundaries are documented.
- [ ] Required plugins and dependencies are explicitly evaluated and selected.
- [ ] Supported debugger adapters are identified.
- [ ] External debugger dependencies are documented and available in the validation environment.
- [ ] Language-specific debugger configurations are implemented.
- [ ] Project-owned debugging keymaps work without collisions.
- [ ] Launch and attach workflows work where supported.
- [ ] Breakpoints, stepping, and variable inspection operate correctly.
- [ ] Debugger termination and cleanup work correctly.
- [ ] Existing language workflows remain intact.
- [ ] Applicable syntax, smoke, and interactive tests pass.

## Stage Closeout

Stage 14 must remain open until its defined implementation and acceptance criteria are satisfied.

---

# Stage 15 — Development Workflows

<badge color="warning">Acceptance Pending</badge>

**Implementation status:** Configuration work complete.

## Objective

Extend the configuration with optional development workflows while preserving modular plugin ownership, explicit dependencies, and native Neovim integration.

This stage provides a dedicated location for development productivity integrations that complement the existing editing, LSP, completion, and formatting architecture.

## Selected Integration

| Plugin | Intended Role | Status |
|---|---|---|
| `codecompanion.nvim` | AI-assisted chat and inline editing | Configuration complete; acceptance pending |

### CodeCompanion

CodeCompanion provides AI-assisted development workflows through a local OpenAI-compatible server.

The integration must remain optional. It must not replace native editing, LSP, completion, or formatting capabilities.

## Scope

Stage 15 covers the following responsibilities:

- Configure CodeCompanion through its dedicated plugin module.
- Keep provider and adapter configuration explicit.
- Document local OpenAI-compatible server requirements.
- Keep credentials and sensitive configuration out of the repository.
- Define project-owned keymaps.
- Preserve existing language and editing workflows.
- Validate chat, inline editing, and provider connectivity.

## Implementation Boundaries

- Do not introduce another AI plugin without an explicit architectural decision.
- Do not make an external AI service mandatory for ordinary Neovim startup.
- Keep local server configuration separate from plugin configuration where appropriate.
- Avoid conflicts with existing keymap namespaces.
- Keep external services and executables separate from Neovim plugin installation.
- Successful plugin loading does not establish successful provider connectivity or working AI workflows.

## Completion Criteria

Stage 15 must satisfy the following requirements before formal closeout:

- [x] CodeCompanion configuration is implemented.
- [ ] CodeCompanion loads through the normal configuration startup path.
- [ ] Provider and adapter configuration is valid.
- [ ] The local OpenAI-compatible server is reachable.
- [ ] Chat workflows operate successfully.
- [ ] Inline editing workflows operate successfully.
- [ ] Project-owned mappings work without collisions.
- [ ] Existing LSP, completion, formatting, and editing workflows remain intact.
- [ ] External requirements and configuration instructions are documented.
- [ ] Applicable syntax, smoke, and interactive tests pass.

## Stage Closeout

Stage 15 remains open until all defined acceptance criteria are satisfied.

Configuration implementation is complete, but formal acceptance has not yet been granted.
