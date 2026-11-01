# Roadmap

## Current Status

- **Stages 01–03:** Complete.
- **Stage 04 — Native Workflows:** In progress. The native commenting workflow remains unresolved.
- **Stages 05–09:** Complete. Stage 09's native LSP and lazydev implementation and defined validation are closed out.
- **Stage 10 — Completion and Snippets:** Implementation is in place; interactive verification remains in progress.
- **Stage 11 — Format and Lint:** Complete for the defined manual formatting implementation and automated validation. Python's Ruff native LSP lint integration has also been implemented and validated as part of the Stage 13 Python pack.
- **Stage 12 — Git, Root, and Sessions:** In progress. Gitsigns, `DrKJeff16/project.nvim`, and `mini.sessions` are implemented. Interactive checks for Git workflows, project navigation, and session save/restore have passed. The Stage 12 smoke-test checks also pass on Neovim 0.12.6. Related documentation, dependency and keymap alignment, and remaining stage-closeout requirements are still outstanding.
- **Stage 13 — Language Packs:** In progress. The Lua and Python language packs are implemented and validated. YAML is the next language pack in the agreed build order. The remaining baseline language packs are pending.
- **Stages 14–17:** Planned.

Later-stage work must not be used to imply that an earlier stage's outstanding requirements have been resolved. In particular, Stage 12 does not reopen Stage 09. Stage 13's completed Lua and Python packs do not close Stage 10 or change the completion status of Stage 11.

> Update this status whenever a stage formally changes. Do not infer completion from the presence of configuration files alone.

---

## Stage 13 — Language Packs

**Status:** In progress — Lua and Python complete; YAML next.

**Objective:** Extend the configuration for selected programming and markup languages while keeping language support modular, dependencies explicit, and tool installation separate from Neovim startup.

### Language baseline

The Stage 13 baseline covers these 11 language groups, in the following implementation order:

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

### Current implementation status

| Language group | Classification | Status |
|---|---|---|
| Lua | Core | Complete |
| Python | Core | Complete |
| YAML | Core | Next |
| JSON | Core | Pending |
| Shell | Core | Pending |
| PowerShell | Core | Pending |
| HTML | Core | Pending |
| CSS | Core | Pending |
| JavaScript/TypeScript | Core | Pending |
| Markdown | Core | Pending |
| Rust | Core | Pending |

HTML and CSS are part of the core baseline. They must not be classified as optional language packs merely because earlier documentation placed HTML under an optional web pack. Align the language index and supporting documentation with this baseline when those packs are implemented.

Optional language packs remain separate from the 11-language core baseline. Their inclusion requires an explicit decision and must not change the agreed core build order.

### Completed language packs

**Lua — Complete**

The Lua language pack has been implemented and validated. Its defined support includes:

- LuaLS through the native Neovim LSP configuration.
- The approved LuaLS runtime and diagnostic settings.
- StyLua formatting through Conform.
- Tree-sitter parsing and highlighting.
- The documented external-tool requirements.

**Python — Complete**

The Python language pack has been implemented and validated. Its defined support includes:

- `uv` for Python project and environment management.
- `ty` for language-server functionality and type diagnostics.
- Ruff CLI for standalone linting.
- Ruff native LSP for editor diagnostics.
- Conform with `ruff_format` for formatting.
- Tree-sitter parsing and highlighting.
- Native Neovim LSP integration for Ty and Ruff.

Ty and Ruff operate as separate LSP clients. Ruff's editor integration is diagnostic-focused; formatting remains the responsibility of Conform. Python validation confirmed both clients attach together and continue to attach after a fresh Neovim start.

The Python pack does not require a manually configured completion shortcut. Automatic completion was verified separately. Any changes to completion mappings or Blink configuration remain within Stage 10.

### Next language pack: YAML

YAML is the next implementation target.

The YAML evaluation should define and validate:

- The YAML language server and its native LSP configuration.
- Prettier formatting through Conform.
- Tree-sitter parser support.
- Schema support through the selected SchemaStore integration.
- External executable requirements and installation guidance.
- Diagnostic behavior and representative YAML project validation.

The YAML pack must preserve the established boundaries: native LSP configuration, Conform-owned formatting, explicit external dependencies, and no automatic tool installation during startup.

### Scope

- Define and maintain the supported language baseline.
- Implement language packs in the agreed build order.
- Document language servers, formatters, linters, parsers, schemas, and other required external tools.
- Keep language-specific configuration modular.
- Reuse the existing native LSP registry and activation architecture from Stage 09.
- Use Conform for the approved formatting workflows.
- Keep external executable installation and updates separate from plugin installation.
- Validate each language independently before marking its pack complete.
- Keep core language support distinct from optional language packs.

### Completion criteria

- Each baseline language has a documented dependency set.
- Each implemented language pack has a clearly defined configuration and responsibility boundary.
- Language-server configuration uses the established native LSP architecture.
- Formatting and linting responsibilities are explicit and do not conflict.
- Required external tools are documented and available in the validation environment.
- Parser, language-server, diagnostic, formatting, and other applicable workflows are validated.
- Language-specific configuration passes syntax and formatting checks.
- The language index and supporting documentation reflect the actual implementation.
- The configuration avoids installing unrelated tools by default.
- A language is marked complete only after its own implementation and required validation are finished.

### Implementation boundaries

- Stage 13 does not reopen Stage 09's completed LSP foundation.
- Stage 13 does not reopen Stage 10's completion and snippet implementation.
- Language-specific lint integration may be implemented and validated within its language pack without implying that every language has lint support.
- Formatting remains manual by default. Do not introduce format-on-save or LSP formatting fallback without a separate decision.
- Do not introduce Mason or Neovim-side external-tool installation.
- Do not mark the entire stage complete while any baseline language pack remains pending.

Stage 13 remains in progress. Lua and Python are complete; YAML is next in the agreed implementation order.
