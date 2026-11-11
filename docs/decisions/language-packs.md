# Language Support

## Purpose

This document is the central index of language support in `nvim-config`.

It defines the language inventory, separates core language support from optional language packs, records the intended tooling direction, and links language-specific implementation details to their dedicated documentation.

The goal is to provide practical language support without turning the configuration into a large, tightly coupled plugin collection.

> **Minimum installation. Compose the rest.**

## 1. Support Model

Language support is divided into two groups:

1. **Core language support** — the baseline languages maintained as part of the main configuration.
2. **Optional language packs** — additional language ecosystems enabled only when explicitly selected.

Some capabilities require separate admission decisions. These include additional linters, renderers, debuggers, and other specialized tools. Their evaluation does not automatically make them part of a language pack.

### Core language support

Core language packs belong under:

`lua/langs/`

They are discovered by the language registry and follow the shared configuration, dependency, formatting, LSP, Tree-sitter, and validation contracts.

### Optional language support

Optional language packs belong under:

`lua/langs/optional/`

They must be explicitly enabled through:

`lua/config/languages.lua`

An optional pack must not load simply because its file exists. Optional packs must also avoid duplicate ownership of filetypes already assigned to core packs.

### Important distinction

A language pack is not the same as a plugin or an external executable.

A pack may use an existing plugin, a language server, a formatter, a linter, or a Tree-sitter parser. These dependencies are managed independently and must be justified by the capabilities they provide.

## 2. Design Principles

The language-support architecture follows these principles:

- Prefer Neovim's built-in capabilities before introducing additional plugins.
- Use the existing `vim.pack` plugin-management workflow.
- Do not introduce Mason as the default external-tool installer.
- Keep language-specific configuration inside focused language-pack modules.
- Keep shared infrastructure outside individual language packs.
- Separate plugin installation from external executable installation.
- Use Neovim's native LSP configuration and activation APIs.
- Keep formatter selection explicit and deterministic.
- Keep linting separate from formatting.
- Keep Tree-sitter configuration centralized.
- Keep optional packs explicitly enabled.
- Validate each language pack independently.
- Add one language pack per implementation commit.
- Preserve visible errors for invalid configuration and missing required definitions.
- Report missing executables accurately.
- Do not enable format-on-save by default.
- Do not enable LSP formatting fallback by default.

A language pack must earn its place through a clear responsibility, a documented dependency contract, representative fixtures, and repeatable validation.

## 3. Language Categories

The inventory uses eight categories to organize language support consistently.

| Category | Scope |
|---|---|
| General-purpose programming | Languages used for application development, scripting, and general software engineering |
| Systems programming | Languages used for low-level development, systems software, and performance-sensitive applications |
| Shell and automation | Shell languages and automation scripting |
| Web development | Browser-facing languages, markup, stylesheets, and web application development |
| Data and configuration | Structured data, configuration formats, and data-processing languages |
| Markup and documentation | Documentation formats and technical publishing |
| Query languages | Database and query-oriented languages |
| Infrastructure and build tools | Container definitions, build systems, and infrastructure configuration |

The categories describe the language's primary role. They do not determine whether a pack is core or optional.

## 4. Core Language Inventory

The following eleven language groups define the Stage 13 baseline.

The implementation order is intentional and must be preserved.

| Order | Language group | Category | Status |
|---:|---|---|---|
| 1 | Lua | General-purpose programming | Validated |
| 2 | Python | General-purpose programming | Validated |
| 3 | YAML | Data and configuration | Validated |
| 4 | JSON | Data and configuration | Validated |
| 5 | Shell | Shell and automation | Planned |
| 6 | PowerShell | Shell and automation | Planned |
| 7 | HTML | Web development | Planned |
| 8 | CSS | Web development | Planned |
| 9 | JavaScript and TypeScript | Web development | Planned |
| 10 | Markdown | Markup and documentation | Planned |
| 11 | Rust | Systems programming | Planned |

The shared data pack also provides support for JSONC, JSON5, jq, and TOML. These capabilities extend the data pack without adding new entries to the eleven-group baseline.

### 4.1 Lua

**Language pack:** `lua/langs/lua.lua`

<badge color="success">Validated</badge>

Lua is the first core language pack and provides the baseline for the shared language architecture.

| Capability | Selection |
|---|---|
| Language server | LuaLS (`lua_ls`) |
| Formatter | StyLua |
| Linter | LuaCheck as an optional standalone CLI tool |
| Tree-sitter parser | `lua` |
| LSP configuration | Neovim native LSP API |

LuaLS is configured through Neovim's native LSP API. Plugin-provided server definitions may be used where appropriate, but Neovim owns configuration and activation.

LuaCheck is not part of the editor's LSP or diagnostics workflow unless a separate admission decision is made.

**Documentation:** See the Lua support documentation and the relevant dependency entries.

### 4.2 Python

**Language pack:** `lua/langs/python.lua`

<badge color="success">Validated</badge>

Python language support is complete for the defined Stage 13 scope.

| Capability | Selection |
|---|---|
| Project and tool workflow | `uv` |
| Language server | Astral Ty |
| Language-server diagnostics | Ty |
| Linter | Ruff CLI (`ruff check`) |
| Native LSP diagnostics | Ruff diagnostic publication and clearing |
| Formatter | Ruff (`ruff format`) through Conform |
| Tree-sitter parser | `python` |
| Completion | Existing automatic completion integration |

The following Python workflows have passed validation:

- The `uv` project workflow.
- Ty language-server functionality and diagnostics.
- Ruff CLI linting through `ruff check`.
- Ruff native LSP diagnostic publication and clearing.
- Ty and Ruff coexistence without conflicting diagnostic behavior.
- Language-server attachment after a fresh Neovim start.
- Ruff formatting through the shared Conform integration.
- Automatic completion.
- Tree-sitter syntax highlighting.

Formatting and LSP diagnostics remain separate responsibilities. Ruff formatting runs through Conform; it is not part of the LSP diagnostic workflow.

Python-specific smoke tests are intentionally skipped. Their omission does not change the completed status of the defined Python scope.

Manual completion shortcut configuration belongs to Stage 10 and is not part of this Stage 13 language-support implementation.

### 4.3 YAML

**Language pack:** `lua/langs/data.lua`

<badge color="success">Validated</badge>

YAML is part of the shared data-language pack rather than a separate `yaml.lua` pack.

| Capability | Selection |
|---|---|
| Language server | YAML Language Server (`yamlls`) |
| Formatter | Prettier |
| Tree-sitter parser | `yaml` |

The pack accounts for YAML-related filetypes, including Docker Compose and other supported YAML variants.

Schema configuration, diagnostics, formatting, and parser behavior are part of the completed YAML support.

### 4.4 JSON and related data formats

**Language pack:** `lua/langs/data.lua`

<badge color="success">Validated</badge>

The shared data pack owns JSON, JSONC, JSON5, jq, and TOML support.

#### JSON formats

| Format | Language server | Formatter | Parser |
|---|---|---|---|
| JSON | JSON Language Server (`jsonls`) | Prettier | `json` |
| JSONC | JSON Language Server (`jsonls`) | Prettier | `json` |
| JSON5 | Not configured | Prettier | `json5` |

JSON and JSONC use the JSON Language Server. JSON5 deliberately uses Tree-sitter and Prettier without JSON Language Server attachment.

#### jq

| Capability | Selection |
|---|---|
| Language server | jq language server (`jq-lsp`) |
| Execution | Native `vim.system()` integration |
| Tree-sitter parser | `jq` |

jq support is complete within the shared data pack.

Execution uses Neovim's native process interface rather than introducing a separate execution framework.

#### TOML

| Capability | Selection |
|---|---|
| Language server | Taplo |
| Formatter | Taplo |
| Tree-sitter parser | `toml` |

TOML support is complete within the shared data pack.

Parser configuration and parser availability remain distinct validation concerns. The configured parser must be available and usable in the running Neovim installation.

#### Data-pack completion scope

The following formats and tools are complete:

- YAML
- JSON
- JSONC
- JSON5
- jq
- TOML

The shared pack must preserve clear filetype ownership, formatter selection, server attachment rules, parser configuration, and dependency reporting for each supported format.

### 4.5 Shell

**Planned language pack:** `lua/langs/shell.lua`

| Capability | Candidate |
|---|---|
| Language server | Bash Language Server (`bashls`) |
| Formatter | `shfmt` |
| Tree-sitter parser | `bash` |

The shell pack covers shell scripting, including Bash.

Validation must cover filetype detection, server attachment, formatter execution, and representative shell scripts.

General terminal integration and command-line tooling are separate from language support.

### 4.6 PowerShell

**Planned language pack:** `lua/langs/powershell.lua`

| Capability | Selection |
|---|---|
| Language server | PowerShell Editor Services (`powershell_es`) |
| Formatter | PSES formatter through the LSP |
| Linter and diagnostics | PSScriptAnalyzer through PSES |
| Tree-sitter parser | `powershell` |

PowerShell is a core language pack and must be validated on the target Windows environment.

PSES provides formatting through its formatter functionality. This differs from packs that use a standalone formatter executable.

The implementation must not claim that a separate CLI formatter exists when formatting is provided through PSES.

### 4.7 HTML

**Planned language pack:** `lua/langs/html.lua` or the agreed core web-pack structure.

HTML belongs to the core baseline.

| Capability | Selection |
|---|---|
| Language server | HTML language server |
| Formatter | Prettier |
| Tree-sitter parser | `html` |

Emmet is opt-in. It must not be enabled automatically merely because HTML support is present.

The implementation must validate HTML filetype detection, language-server behavior, formatting, and parser functionality.

### 4.8 CSS

**Planned language pack:** `lua/langs/css.lua` or the agreed core web-pack structure.

CSS belongs to the core baseline.

| Capability | Selection |
|---|---|
| Language server | CSS language server |
| Formatter | Prettier |
| Tree-sitter parser | `css` |

CSS support must be independently validated. Sharing Prettier with HTML or JavaScript does not remove the need for CSS-specific checks.

### 4.9 JavaScript and TypeScript

**Planned language pack:** `lua/langs/typescript.lua` or the agreed core web-pack structure.

| Capability | Selection |
|---|---|
| Language server | TypeScript Language Server (`ts_ls`) |
| Formatter | Prettier |
| Tree-sitter parsers | `javascript`, `typescript`, `tsx` |

The pack owns the following filetypes:

- `javascript`
- `javascriptreact`
- `typescript`
- `typescriptreact`

The implementation must not allow optional web support to duplicate these filetypes.

Lint-tool selection remains a separate decision. Prettier formatting must not be treated as evidence that linting has been configured.

### 4.10 Markdown

**Planned language pack:** `lua/langs/markdown.lua`

| Capability | Selection |
|---|---|
| Language server | Marksman |
| Formatter | Prettier |
| Tree-sitter parsers | `markdown`, `markdown_inline` |
| Linter | Separate admission decision |
| Renderer | Separate admission decision |

Markdown language support must remain independent of Markdown linting and rendering.

The core Markdown pack must validate:

- Markdown filetype detection.
- Marksman attachment and diagnostics.
- Prettier formatting.
- Both required Tree-sitter parsers.
- Representative Markdown fixtures.
- The manual formatting workflow.

`markdownlint-cli2` remains subject to its own linting admission decision.

Markdown rendering remains subject to an independent compatibility evaluation. Neither linting nor rendering should block the core Markdown pack.

### 4.11 Rust

**Planned language pack:** `lua/langs/rust.lua`

| Capability | Selection |
|---|---|
| Language server | Rust Analyzer (`rust_analyzer`) |
| Formatter | `rustfmt` |
| Tree-sitter parser | `rust` |

Rust support must validate the Rust toolchain, server attachment, formatter behavior, parser availability, and representative Rust projects.

The language pack must use the shared LSP and formatting infrastructure rather than introducing a separate management workflow.

## 5. Optional Language Inventory

Optional language packs extend the core baseline. They are not automatically enabled and must not be treated as installed or supported merely because they appear in this index.

They must be explicitly selected through `lua/config/languages.lua`.

| Optional pack | Category | Scope | Decision |
|---|---|---|---|
| Typst | Markup and documentation | Typst documents and technical publishing | Confirmed for evaluation |
| SQL | Query languages | SQL editing and database-oriented workflows | Pending tooling decision |
| Go | General-purpose programming | Go application development | Candidate |
| Java | General-purpose programming | Java and JVM development | Candidate |
| Zig | Systems programming | Zig development | Candidate |
| Kotlin | General-purpose programming | Kotlin and JVM development | Pending tooling decision |
| Julia | General-purpose programming | Scientific and technical computing | Candidate |
| Docker | Infrastructure and build tools | Dockerfiles and container definitions | Pending tooling decision |
| CMake | Infrastructure and build tools | CMake build configuration | Pending tooling decision |

### Optional-pack rules

- Optional packs live under `lua/langs/optional/`.
- Optional packs must be explicitly enabled.
- An enabled pack without a matching implementation file is a configuration error.
- Optional packs must follow the same metadata and validation contracts as core packs.
- Optional packs must not claim filetypes already owned by core packs.
- Optional dependencies must not be installed automatically.
- A pack must have a clear use case and a defined validation path before admission.

### Typst

Typst is confirmed as an optional language-support target.

Its implementation, dependencies, parser requirements, formatter selection, and documentation must be evaluated independently.

Confirmation of Typst as a target does not mean its tools or plugins are already admitted or installed.

### SQL

SQL tooling remains undecided.

The language server and formatter must be selected after evaluating the intended database-agnostic workflow, project requirements, and external dependencies.

### Go

Go may use `gopls` and the standard Go formatting toolchain.

The implementation must validate the required Go runtime and toolchain rather than assuming that Neovim alone provides them.

### Java

Java tooling must be evaluated against the intended JVM workflow and project requirements.

The language server, runtime, formatter, and project-root behavior must be verified before implementation.

### Zig

Zig support requires an evaluation of the available language-server and formatter options against the selected Zig toolchain.

### Kotlin

Kotlin tooling remains undecided.

The implementation must account for the intended Kotlin/JVM workflow and its runtime and project requirements.

### Julia

Julia support requires a defined runtime, language-server workflow, and formatter decision.

### Docker

Docker support covers Dockerfiles and related container configuration.

The implementation must establish filetype ownership and evaluate the language server and formatter before admission.

### CMake

CMake support covers `CMakeLists.txt` and `.cmake` files.

Tool selection must be based on verified installation requirements and actual project needs.

## 6. Shared Language-Pack Architecture

Language-specific configuration must remain modular while shared behavior stays centralized.

| Component | Responsibility |
|---|---|
| `lua/langs/init.lua` | Discover core packs, initialize them, and collect metadata |
| `lua/langs/*.lua` | Define core language packs |
| `lua/langs/optional/*.lua` | Define explicitly enabled optional packs |
| `lua/config/languages.lua` | User-facing optional-pack selection and formatter preferences |
| `lua/config/format.lua` | Shared Conform formatting workflow |
| `lua/config/lsp.lua` | Shared native LSP behavior |
| `lua/plugins/treesitter.lua` | Centralized Tree-sitter configuration |
| `docs/dependencies.md` | External tools, runtimes, installation, and verification |
| `docs/plugin-inventory.md` | Plugin admission and inventory |
| `scripts/smoke.lua` | Automated configuration and regression checks |

### Registry contract

The language registry is responsible for discovering language packs, invoking their setup functions, and collecting declared metadata.

A language pack must provide a `setup()` function.

Metadata collection must detect duplicate ownership rather than silently allowing one pack to overwrite another.

Language packs should declare capabilities. They should not independently reimplement the shared LSP, formatting, or Tree-sitter infrastructure.

### Optional-pack activation

Optional packs must remain opt-in.

The registry must not load every file in `lua/langs/optional/` automatically. Only explicitly enabled packs should be initialized.

Invalid optional-pack names must produce visible errors.

## 7. Formatting Contract

All language packs must use the existing formatting architecture in `lua/config/format.lua` and the Conform integration.

The default workflow is manual:

```vim
:Format
```

The associated keymap is:

```text
<leader>cf
```

The formatting contract is:

- Format-on-save is disabled by default.
- LSP formatting fallback is disabled by default.
- Formatter selection is deterministic.
- User preferences are resolved ahead of pack defaults.
- Duplicate formatter entries are removed.
- Exclusive formatter preferences must not fall back to pack defaults.
- Missing formatters must be reported clearly.
- Formatting must not silently report success when no formatter runs.

Language packs must declare formatter metadata. They must not independently configure a second formatting framework.

## 8. LSP Contract

Language servers use Neovim's native LSP configuration and activation APIs.

The project must not introduce a separate language-server manager.

The shared LSP configuration owns common behavior, while language packs provide language-specific server setup and metadata.

Requirements:

- Use valid server identifiers.
- Verify server definitions and executable requirements.
- Keep shared LSP keymaps centralized.
- Avoid duplicate server ownership.
- Validate server attachment using representative fixtures.
- Report unavailable executables accurately.
- Keep project-root behavior consistent with the existing root-management architecture.

A configured server is not proof that it is installed, starts successfully, or attaches to a buffer.

## 9. Tree-sitter Contract

Tree-sitter configuration remains centralized in:

`lua/plugins/treesitter.lua`

Language packs must not independently initialize or reconfigure the shared Tree-sitter plugin.

For every supported language, verify:

- The parser is included in the configured parser set.
- The parser can be installed or is already available.
- Neovim can create a syntax tree for a representative fixture.
- Highlighting works where enabled.
- Parser names match the actual Tree-sitter configuration.

Parser availability, syntax-tree parsing, and highlighting are separate validation results.

A parser name appearing in a configuration file is not proof that the parser works.

## 10. Linting and Rendering Gates

Some tools require separate admission decisions and must not be bundled into core language support without evaluation.

### Markdown linting

`markdownlint-cli2` is a candidate for Markdown linting.

Its admission must establish:

- Executable and runtime requirements.
- Rule policy and configuration ownership.
- Direct CLI or Neovim integration.
- Whether `nvim-lint` is required.
- Useful diagnostics on valid and invalid fixtures.
- Dependency documentation.

Markdown formatting and linting remain separate responsibilities.

### Markdown rendering

`md-render.nvim` is a rendering candidate, not an automatically admitted dependency.

The initial compatibility target is:

- Windows.
- Neovim 0.12.6.
- WezTerm.

The isolated evaluation must cover normal Markdown content, tables, code blocks, local images, remote images, scrolling, resizing, preview cleanup, and preservation of the source buffer.

Image rendering must be tested in the actual target terminal. A text-only preview does not satisfy a requirement for inline image rendering.

The renderer must not become a dependency of the core Markdown pack until the isolated compatibility evaluation passes.

## 11. External Dependencies

External executables and language runtimes are managed independently of Neovim plugin installation.

`docs/dependencies.md` is the central reference for external tools and runtimes.

For every language, document applicable requirements:

- Language server.
- Formatter.
- Linter.
- Runtime or compiler.
- Required executable names.
- Installation method.
- Platform requirements.
- Verification commands.
- Required, optional, or pending status.

Do not silently install tools because a language pack references them.

Do not require every language runtime merely to start Neovim. Missing language-specific dependencies should affect only the corresponding features where practical, with clear diagnostics.

## 12. Language-Pack Acceptance Criteria

A language pack is complete only when its implementation and validation evidence support that status.

| Area | Required evidence |
|---|---|
| Filetype | Neovim assigns the expected filetype |
| Registry | The pack is discovered and its metadata is valid |
| LSP | Server definition, executable, attachment, and diagnostics are verified |
| Formatting | The intended formatter is selected and its output is checked |
| Linting | Lint behavior is validated when included |
| Tree-sitter | Required parser is available and usable |
| Dependencies | External tools and runtimes are documented and checked |
| Fixtures | Representative source files exercise real language constructs |
| Status | `:LangStatus` reports relevant support and dependency state |
| Regression | Applicable automated smoke tests and syntax checks pass |

Not every language requires a separate linter.

A language pack must not claim a capability that has not been selected, integrated, and validated.

### Status terminology

Use these terms consistently:

| Status | Meaning |
|---|---|
| Planned | Included in the agreed support scope but not implemented |
| Implemented | Configuration and required files exist |
| Validated | Defined automated and interactive checks have passed |
| Admitted | The relevant plugin or tool has passed its separate admission decision |
| Deferred | Work is intentionally postponed |
| Rejected | The candidate was evaluated and not accepted |

These statuses are not interchangeable.

An installed tool does not prove that its integration works. A configured language server does not prove that it attaches successfully. A documented plan does not prove implementation.

The status in the inventory describes the language-support implementation. Admission status for individual optional tools and plugins remains separate.

### Python validation exception

Python-specific smoke tests are intentionally skipped.

The completed Python status is based on the defined manual and interactive validation scope documented in the Python section. The general acceptance criteria do not imply that Python-specific automated smoke tests have passed.

Manual completion shortcut configuration belongs to Stage 10. It is not a Stage 13 Python acceptance requirement.

## 13. Implementation Order

The core baseline must follow the agreed order:

| Order | Language group | Current status | Required completion evidence |
|---:|---|---|---|
| 1 | Lua | Validated | LuaLS, StyLua, parser, syntax checks, and language-specific validation |
| 2 | Python | Validated | `uv` project workflow, Ty diagnostics, Ruff CLI linting, Ruff LSP diagnostics, coexistence, fresh-start attachment, Conform formatting, automatic completion, and Tree-sitter highlighting |
| 3 | YAML | Validated | Filetypes, YAML Language Server, Prettier, parser, and fixtures |
| 4 | JSON | Validated | JSON/JSONC/JSON5 ownership, server behavior, Prettier, parsers, and fixtures |
| 5 | Shell | Planned | Bash server, `shfmt`, parser, and representative scripts |
| 6 | PowerShell | Planned | PSES, PSScriptAnalyzer, formatting, Windows validation, and parser |
| 7 | HTML | Planned | Filetype, server, Prettier, parser, and fixture |
| 8 | CSS | Planned | Filetype, server, Prettier, parser, and fixture |
| 9 | JavaScript/TypeScript | Planned | `ts_ls`, Prettier, filetype ownership, parsers, and fixtures |
| 10 | Markdown | Planned | Marksman, Prettier, both Markdown parsers, and fixtures |
| 11 | Rust | Planned | Rust Analyzer, `rustfmt`, toolchain, parser, and fixture |

The shared data pack also has completed support for JSONC, JSON5, jq, and TOML. These formats are additional data-pack capabilities and do not change the eleven-group implementation order.

Implement and validate one language pack at a time.

If a pack fails its acceptance criteria, resolve the failure before moving to the next pack.

Optional packs follow only after their individual admission and implementation decisions.

## 14. Documentation Ownership

This index does not replace language-specific support documentation.

| Document | Responsibility |
|---|---|
| `docs/langs-support.md` | Central language inventory and support index |
| `docs/dependencies.md` | External tools, runtimes, and installation |
| `docs/plugin-inventory.md` | Plugin inventory and admission status |
| `docs/architecture.md` | Shared configuration architecture |
| `docs/roadmap.md` | Overall project stages and progress |
| Language-specific support documents | Detailed implementation, configuration, dependencies, and validation |

Update the index when a language is added, removed, promoted, deferred, or validated.

Do not mark a language as complete until its dedicated documentation and validation evidence support that status.

## 15. Definition of Done

The language-support index and Stage 13 work are ready for completion when:

- All eleven core language groups have been implemented and validated.
- Existing Lua support remains correct.
- Python's `uv`, Ty, Ruff linting, Ruff LSP diagnostics, Conform formatting, completion, and Tree-sitter workflows are validated.
- YAML and JSON support meet their individual acceptance criteria.
- JSONC, JSON5, jq, and TOML support remain covered by the shared data-pack acceptance criteria.
- Shell and PowerShell support pass their platform-specific checks.
- HTML and CSS remain part of the core baseline.
- JavaScript and TypeScript have clear filetype ownership.
- Markdown's core workflow is independent of linting and rendering decisions.
- Rust support is validated against its toolchain.
- Optional packs remain explicitly enabled.
- Typst's optional-pack implementation and dependencies are independently evaluated.
- The shared registry rejects invalid configuration and duplicate metadata.
- Formatter preferences and exclusive formatter lists are tested.
- Manual formatting remains the default.
- Format-on-save and LSP formatting fallback remain disabled by default.
- Required Tree-sitter parsers and LSP definitions are verified.
- External dependencies are documented accurately.
- `:LangStatus` provides useful support and dependency information.
- Applicable automated smoke tests and syntax checks pass.
- The language index, dependency documentation, plugin inventory, and roadmap reflect verified status.

Python-specific smoke tests remain intentionally skipped and are not represented as completed automated checks.

## Guiding Principles

> **Minimum installation. Compose the rest.** **Approval is not installation.**

Every language pack and optional component must justify its responsibility, dependencies, configuration, and validation requirements.

The objective is not to support every language by default. It is to maintain a reliable, modular baseline and make additional support available through deliberate, independently validated decisions.
