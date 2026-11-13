# Markdown Support

## 1. Purpose

This document defines the architecture, implementation, dependencies, workflows, compatibility expectations, and maintenance requirements for Markdown support in `nvim-config`.

Markdown support is implemented as a language pack that integrates Neovim's native capabilities with explicitly managed external tools and independently maintained plugins.

The implementation follows the project's core philosophy:

> Minimum installation. Compose the rest.

The objective is to provide a reliable Markdown authoring environment without making rendering plugins, external diagram tools, or optional extensions mandatory for ordinary Markdown editing.

The document serves as:

- The architectural specification for Markdown support.
- A reference for implementation ownership and integration boundaries.
- A description of external dependencies and their management.
- A record of accepted and optional Markdown tooling.
- A compatibility and regression-testing contract.
- A maintenance reference for future changes.

It documents the existing implementation and its accepted architecture. It does not authorize unrelated changes or reopen completed implementation stages.

## 2. Scope and Implementation Status

### 2.1 Core Markdown support

Stage 13 — Language Packs is complete.

The Markdown language pack is implemented and enabled through centralized language configuration. Its integrations use the established language-pack, native LSP, Tree-sitter, formatting, and command-registration architecture.

| Capability | Implementation | Status |
|---|---|---|
| Language-pack registration | `lua/langs/markdown.lua` | Implemented |
| Centralized activation | `lua/config/languages.lua` | Implemented |
| Tree-sitter | `markdown` and `markdown_inline` | Implemented |
| Language server | Marksman | Implemented |
| Formatting | Prettier through Conform | Implemented |
| Linting | `markdownlint-cli2` | Implemented |
| Table of contents | `@frat/markdown-toc` | Implemented |
| Mermaid command | Dedicated Lua integration | Implemented |
| Default Markdown renderer | `md-render.nvim` | Accepted |
| Windows Markdown dependencies | `markdown-deps.ps1` | Implemented and tested |

The implementation and integration work listed above has been reported as completed and tested in the target Windows environment.

This status does not imply that every optional extension, operating system, terminal emulator, or Markdown rendering edge case has been validated.

### 2.2 Rendering and optional extensions

| Component | Role | Admission status |
|---|---|---|
| `delphinus/md-render.nvim` | Default in-editor Markdown renderer | Accepted |
| `MeanderingProgrammer/render-markdown.nvim` | Alternative in-buffer renderer | Optional |
| `iamcco/markdown-preview.nvim` | Optional browser-based Markdown preview | Optional |
| Mermaid | Baseline diagram format | Implemented |
| D2 | Additional diagram format | Optional |
| archDraw | Specialized infrastructure-diagram format | Optional |
| `budoux.lua` | Japanese phrase segmentation | Optional |

Optional components must remain independent of core Markdown editing.

Their presence in this document does not mean they are installed, enabled, or required.

### 2.3 Compatibility maintenance

The following areas remain explicit compatibility and regression-testing concerns:

- Marksman behavior with Markdown documents.
- CommonMark syntax and soft-break behavior.
- Paragraph continuation inside list items.
- Paragraph continuation inside blockquotes.
- CJK-aware paragraph joining.
- CJK-aware line wrapping.
- Japanese kinsoku behavior.
- Mixed CJK and Latin text.

These are ongoing maintenance concerns. They do not change the completed status of Stage 13.

## 3. Design Principles

### 3.1 Native-first integration

Prefer Neovim's native functionality when it provides the required behavior.

The Markdown implementation uses:

- Native LSP APIs.
- Native Tree-sitter integration.
- Native diagnostic APIs.
- Native user commands.
- Native asynchronous process execution.
- Existing shared formatting infrastructure.

Plugins and external tools should provide capabilities that justify their additional dependencies.

### 3.2 Explicit component ownership

Each component must have a clearly defined responsibility.

| Responsibility | Owner |
|---|---|
| Language-pack activation | `lua/config/languages.lua` |
| Markdown integration coordination | `lua/langs/markdown.lua` |
| Markdown LSP configuration | `lua/lsp/servers/marksman.lua` |
| Parser registration and installation | Shared Tree-sitter integration |
| Formatting selection | Language-pack metadata and shared formatter resolver |
| Linting | `lua/langs/markdown/lint.lua` |
| TOC generation | `lua/langs/markdown/toc.lua` |
| Dedicated Mermaid rendering | `lua/langs/markdown/mermaid.lua` |
| Default in-editor rendering | `lua/plugins/md-render.lua` |
| User-facing mappings | `lua/config/keymaps.lua` |
| Windows Markdown CLI dependencies | `scripts/core/windows/markdown-deps.ps1` |

Do not introduce duplicate configuration ownership for an existing responsibility.

### 3.3 Explicit dependency management

Neovim must not silently install external executables or optional tools.

External dependencies are managed outside the Neovim plugin configuration.

The implementation must:

- Detect missing executables.
- Report actionable errors.
- Avoid implicit installation.
- Keep optional dependencies optional.
- Avoid changing persistent system configuration without an explicit decision.

### 3.4 Independent workflows

Editing, formatting, linting, TOC generation, diagram rendering, and preview rendering are separate workflows.

A failure in an optional rendering dependency must not prevent ordinary Markdown editing.

A successful language-server attachment must not be treated as proof that rendering works.

Likewise, successful Markdown rendering must not be treated as proof that linting or formatting is correctly configured.

### 3.5 Preserve unsaved content

Commands that operate on the current Markdown document should use the current buffer contents when their workflow requires it.

They must not silently save the document or discard unsaved changes.

### 3.6 Manual activation

Formatting, linting, TOC generation, Mermaid rendering, and Markdown preview activation remain explicit operations.

Automatic linting, automatic TOC generation, automatic Mermaid rendering, and automatic preview activation are not part of the default workflow.

## 4. Architecture

### 4.1 Repository structure

The current Markdown-related implementation is organized as follows:

```text
nvim-config/
├── .markdownlint-cli2.yaml
│
├── lua/
│   ├── config/
│   │   ├── languages.lua
│   │   └── keymaps.lua
│   │
│   ├── langs/
│   │   ├── markdown.lua
│   │   └── markdown/
│   │       ├── lint.lua
│   │       ├── toc.lua
│   │       └── mermaid.lua
│   │
│   ├── lsp/
│   │   └── servers/
│   │       └── marksman.lua
│   │
│   └── plugins/
│       ├── md-render.lua
│       └── treesitter.lua
│
├── scripts/
│   ├── core/
│   │   └── windows/
│   │       └── markdown-deps.ps1
│   │
│   └── markdownlint/
│       ├── formatter.mjs
│       └── validate-config.mjs
│
└── docs/
    └── architecture/
        ├── markdown-support.md
        ├── markdown-linting.md
        └── mdx-support.md
```

This tree identifies the principal Markdown-related files. It does not represent every shared module used by the language pack, formatter resolver, plugin manager, or Tree-sitter infrastructure.

### 4.2 Language-pack coordinator

The entry point is:

`lua/langs/markdown.lua`

It declares:

- Formatter metadata.
- Primary Tree-sitter parser metadata.
- Additional parser dependencies.
- Markdown-specific integration initialization.

The pack's setup function initializes:

1. Marksman.
2. Markdown linting.
3. Table-of-contents generation.
4. Mermaid rendering.

The language pack does not own the implementation of shared LSP, formatting, or Tree-sitter infrastructure.

### 4.3 Centralized activation

Markdown activation is controlled by:

`lua/config/languages.lua`

The current configuration enables Markdown and MDX independently.

The Markdown pack must remain independently configurable. Disabling Markdown must not implicitly disable MDX or other language packs.

### 4.4 Shared infrastructure boundaries

The Markdown pack contributes metadata to existing shared infrastructure.

It must not introduce another formatter resolver, parser installer, LSP coordinator, or plugin loader.

Only metadata consumed by the shared infrastructure should be added to the language pack.

In particular, parser metadata distinguishes the primary parser from additional parser dependencies.

The Markdown pack does not need an `executables` or `servers` metadata field unless a validated shared consumer is introduced through a separate architectural decision.

## 5. Markdown Specifications and Compatibility

### 5.1 CommonMark

CommonMark defines the portable Markdown syntax baseline.

Reference:

https://spec.commonmark.org/current/

Compatibility fixtures should cover:

- ATX and setext headings.
- Paragraphs.
- Soft and hard line breaks.
- Thematic breaks.
- Ordered and unordered lists.
- Nested lists.
- List-item continuation paragraphs.
- Blockquotes and nested blockquotes.
- Blockquote continuation paragraphs.
- Indented and fenced code blocks.
- Inline code.
- Emphasis and strong emphasis.
- Links and images.
- Autolinks.
- Raw HTML.
- Backslash escapes.
- Character references.

CommonMark behavior must be tested independently from GitHub Flavored Markdown extensions.

### 5.2 GitHub Flavored Markdown

GitHub Flavored Markdown (GFM) extends CommonMark.

Reference:

https://github.github.com/gfm/

GFM is the default authoring profile for repository documentation.

Additional compatibility fixtures should cover:

- Tables.
- Task lists.
- Strikethrough.
- Bare URL autolinks.
- Bare email autolinks.
- GFM-specific raw HTML filtering.

A renderer's support for CommonMark must not automatically be interpreted as complete GFM support.

Likewise, a successful GFM rendering test does not replace validation against the CommonMark specification.

### 5.3 Separate specification fixtures

Maintain separate fixture groups for:

1. CommonMark.
2. GFM.
3. CJK behavior.
4. Renderer-specific behavior.
5. Linting.
6. MDX.

This separation makes failures easier to identify.

A GFM extension failure should not be confused with a CommonMark parsing failure. A renderer-specific layout issue should not be reported as an LSP failure.

### 5.4 Soft-break behavior

A soft break occurs when a line ends without an explicit hard-break marker.

The renderer must preserve the semantic distinction between a soft break and a hard break.

Tests should cover:

- Consecutive lines in a paragraph.
- Paragraph boundaries.
- Explicit hard breaks.
- Soft breaks inside list items.
- Soft breaks inside blockquotes.
- Soft breaks in mixed CJK and Latin text.

A visual line wrap must not be mistaken for a source-level paragraph break.

### 5.5 List-item continuation

Markdown list items can contain multiple paragraphs and nested block structures.

Compatibility tests should cover:

- Continuation lines belonging to the same paragraph.
- Continuation paragraphs inside a list item.
- Nested lists.
- Nested blockquotes.
- Fenced code blocks inside list items.
- Blank lines that separate blocks.
- Ordered and unordered list combinations.

The renderer must not incorrectly detach continuation content from its parent list item.

### 5.6 Blockquote continuation

Blockquotes can contain multiple paragraphs, nested blockquotes, lists, and code blocks.

Tests should cover:

- Consecutive quoted lines.
- Paragraph continuation.
- Multiple paragraphs within a blockquote.
- Nested blockquotes.
- Lists inside blockquotes.
- Blockquotes inside list items.
- Blank lines and block boundaries.

Continuation behavior must be checked against the intended Markdown syntax, not inferred from indentation alone.

### 5.7 CJK paragraph joining

CJK text requires careful treatment because Japanese and Chinese writing commonly do not use spaces between adjacent characters.

The renderer must not introduce unintended spaces when joining source lines that belong to the same paragraph.

Test at least:

- Japanese text.
- Simplified Chinese text.
- Traditional Chinese text.
- Mixed CJK and Latin text.
- CJK text containing punctuation.
- CJK text containing inline code and links.
- CJK text with source-level soft breaks.
- CJK text with explicit paragraph boundaries.

The expected behavior must distinguish a semantic paragraph break from a source line break.

### 5.8 CJK-aware line wrapping

Line wrapping must account for CJK character boundaries and punctuation behavior.

Tests should cover:

- Japanese and Chinese text.
- Mixed-width Latin and CJK text.
- Long unbroken CJK sequences.
- Inline code and links.
- Opening and closing punctuation.
- Narrow terminal widths.
- Resizing the terminal.
- Different font and terminal-cell-width conditions where applicable.

### 5.9 Kinsoku behavior

Japanese typography uses kinsoku rules to restrict certain punctuation at line boundaries.

The rendering compatibility contract should document and test the behavior of:

- Opening punctuation that should not appear at the end of a line.
- Closing punctuation that should not appear at the beginning of a line.
- Small kana and other characters with line-boundary restrictions.
- Mixed Japanese and Latin text.
- Narrow display widths.

The implementation should not claim complete Japanese typographic conformance without a defined test corpus and verified results.

### 5.10 Marksman responsibility boundary

Marksman provides Markdown language intelligence.

It is not the CommonMark specification, the Markdown parser, or the Markdown renderer.

Marksman validation should focus on:

- Server executable detection.
- Server configuration.
- Attachment to Markdown buffers.
- Link navigation.
- Heading navigation.
- References and document relationships where supported.
- Diagnostics.
- Workspace and root detection behavior.

CommonMark, GFM, CJK joining, and visual wrapping must be validated through the appropriate parser and renderer workflows.

## 6. Tree-sitter Integration

### 6.1 Parser responsibilities

Markdown uses two Tree-sitter parsers:

| Parser | Responsibility |
|---|---|
| `markdown` | Markdown block structure |
| `markdown_inline` | Inline Markdown syntax |

The primary filetype mapping is:

```lua
markdown = "markdown"
```

The additional parser dependency is:

```lua
markdown = {
  "markdown_inline",
}
```

### 6.2 Shared parser infrastructure

The language pack supplies parser metadata to the shared Tree-sitter integration.

The shared integration:

- Collects parser mappings from enabled language packs.
- Validates parser metadata.
- Registers filetype-to-parser mappings.
- Checks parser availability.
- Installs missing parsers through the configured Tree-sitter plugin workflow.
- Starts highlighting when the primary parser is available.
- Tracks parser installation requests to avoid duplicate work.

The Markdown pack must not introduce a separate parser installation mechanism.

### 6.3 Parser dependencies

`markdown_inline` is an additional parser dependency.

It is installed for Markdown support but is not registered as the primary parser for the Markdown buffer.

This distinction must be preserved when modifying language-pack metadata.

### 6.4 Validation

Verify:

- Both parser names resolve correctly.
- The primary parser is registered for Markdown.
- The additional parser is installed.
- Markdown highlighting works.
- Inline Markdown syntax is parsed correctly.
- Fenced code blocks are recognized.
- Missing parser installations produce actionable diagnostics.

Tree-sitter parser installation and rendering are separate workflows.

A successful parser installation does not prove that a Markdown renderer supports the same syntax.

## 7. Markdown Language Server

### 7.1 Marksman

Marksman is the selected Markdown language server.

Repository:

https://github.com/artempyanykh/marksman

Its responsibilities include Markdown language intelligence, document navigation, link-related features, and diagnostics supported by the server.

It does not replace Tree-sitter, Prettier, markdownlint, or the Markdown renderer.

### 7.2 Native LSP configuration

The server definition is:

`lua/lsp/servers/marksman.lua`

It uses Neovim's native APIs:

- `vim.lsp.config()`
- `vim.lsp.enable()`

The executable is resolved through:

```lua
vim.fn.exepath("marksman")
```

The server configuration uses:

```lua
cmd = {
  marksman,
  "server",
}
```

The configured filetype is `markdown`.

The root markers are:

- `.marksman.toml`
- `.git`

The server is configured only when the executable is available.

### 7.3 Dependency management

Marksman is an external executable.

It is not installed by the Markdown language pack or by Neovim's plugin manager.

The executable must be installed and available on Neovim's `PATH`.

Missing Marksman must not be represented as successful server startup.

### 7.4 Validation

Verify:

- Executable detection.
- Server configuration.
- Server startup.
- Markdown buffer attachment.
- Link navigation.
- Heading navigation.
- Diagnostics.
- Workspace root behavior.
- Behavior when Marksman is unavailable.

Use the current native LSP architecture. Do not introduce `require("lspconfig")` into the server implementation.

## 8. Markdown Formatting

### 8.1 Prettier

Prettier is the selected Markdown formatter.

Reference:

https://prettier.io/docs

The Markdown language pack declares:

```lua
formatters = {
  markdown = { "prettier" },
}
```

Formatting is integrated through the existing Conform infrastructure.

### 8.2 Formatting policy

The default workflow is manual formatting through:

```vim
:Format
```

Format-on-save remains disabled by default.

The Markdown pack must not introduce a separate formatting command or formatter-selection system.

### 8.3 Formatter resolution

Formatter selection belongs to the shared language and formatter infrastructure.

The Markdown pack declares its default formatter metadata. Centralized language configuration may customize formatter preferences according to the existing shared policy.

The implementation must preserve:

- Deterministic formatter selection.
- Existing formatter preference rules.
- Missing-executable diagnostics.
- Explicit formatting behavior.
- The shared `formatters_only` policy.

### 8.4 LSP formatting boundary

Marksman is not the default Markdown formatter.

Do not enable an automatic LSP formatting fallback for Markdown without a separate architectural decision.

### 8.5 Validation

Verify:

- Prettier executable detection.
- Formatter metadata collection.
- Formatter resolution.
- `:Format` on representative Markdown documents.
- Formatting of lists, tables, links, and code blocks.
- Behavior when Prettier is unavailable.
- Preservation of unsaved buffer content until the user explicitly saves.

## 9. Markdown Linting

### 9.1 Tool selection

The implementation uses `markdownlint-cli2`.

Repository:

https://github.com/DavidAnson/markdownlint-cli2

The central configuration is:

`.markdownlint-cli2.yaml`

The configuration defines the HETFS Markdown quality baseline.

Rules are enabled by default, with explicit rule parameters and exceptions.

### 9.2 Neovim integration

The integration is:

`lua/langs/markdown/lint.lua`

The user-facing command is:

```vim
:MarkdownLint
```

The command runs only when explicitly invoked.

Linting is not automatically triggered on save.

### 9.3 Execution architecture

The integration:

1. Resolves Node.js and `markdownlint-cli2`.
2. Resolves the CLI's Node.js entry point.
3. Locates the HETFS baseline configuration.
4. Locates the project-level Markdown configuration.
5. Validates the project configuration.
6. Captures the current buffer content.
7. Sends the content through standard input.
8. Receives structured JSON output.
9. Validates the diagnostic contract.
10. Publishes findings through `vim.diagnostic`.

The implementation uses asynchronous process execution.

It does not need to save the current buffer before linting.

### 9.4 HETFS baseline and project overrides

The HETFS configuration is always supplied as the baseline.

Project-level configuration may override Markdown rules through the supported configuration format.

The project validator is:

`scripts/markdownlint/validate-config.mjs`

The validator checks the project-level CLI configuration format and requires rule overrides to be contained under `config:`.

The supported project-level configuration file is:

`.markdownlint-cli2.yaml`

The validator recognizes other CLI configuration filenames so it can report unsupported project configuration formats rather than silently ignoring them.

This validation is important because markdownlint-cli2 options and Markdown rule overrides have different configuration responsibilities.

### 9.5 Structured diagnostic formatter

The custom formatter is:

`scripts/markdownlint/formatter.mjs`

It converts markdownlint-cli2 findings into structured JSON.

The output includes information such as:

- File name.
- Line number.
- Column.
- Diagnostic length.
- Severity.
- Rule names.
- Rule description.
- Error detail.
- Error context.

The Neovim integration validates the returned JSON before publishing diagnostics.

This protects the diagnostic layer from malformed or unexpected formatter output.

### 9.6 Unsaved-buffer handling

The integration sends the current buffer contents through standard input.

It preserves the current end-of-line state when preparing the content.

The document does not need to be saved before linting.

### 9.7 Project root discovery

Named buffers use project configuration markers to discover the project root.

The implementation recognizes:

- `.markdownlint-cli2.jsonc`
- `.markdownlint-cli2.yaml`
- `.markdownlint-cli2.cjs`
- `.markdownlint-cli2.mjs`

If no matching root is found, it falls back to Neovim's current working directory.

Unnamed buffers do not provide a normal file path for project root discovery. Their fallback is therefore Neovim's current working directory.

### 9.8 Asynchronous result safety

The integration tracks requests per buffer.

It uses request identity and the buffer's changedtick to reject stale results.

It also handles:

- Invalid or unloaded buffers.
- Superseded requests.
- Process startup failures.
- Nonzero process exit codes.
- Malformed JSON.
- Invalid diagnostic fields.
- Missing dependencies.
- Invalid project configuration.

A lint result must not overwrite diagnostics for a buffer that has changed since the request started.

### 9.9 Exit code handling

A markdownlint-cli2 exit code of `1` is valid when lint findings are present.

Other nonzero exit codes are treated as execution failures.

The integration must distinguish lint findings from process failures.

### 9.10 Validation

Verify:

- Valid Markdown documents.
- Deliberate lint violations.
- Rule overrides.
- Unsupported project configuration formats.
- Invalid configuration structure.
- Named-buffer project root discovery.
- Current working directory fallback.
- Unsaved buffer input.
- Structured JSON output.
- Diagnostic publication.
- Stale-result rejection.
- Malformed JSON.
- Missing Node.js.
- Missing markdownlint-cli2.
- Process startup and exit-code handling.

## 10. Markdown Table of Contents

### 10.1 Tool selection

The implementation uses:

`@frat/markdown-toc`

Package:

https://www.npmjs.com/package/@frat/markdown-toc

The verified package version is `1.3.0`.

The global installation command is:

```powershell
npm install --global @frat/markdown-toc
```

The executable is:

```text
markdown-toc
```

### 10.2 Neovim integration

The implementation is:

`lua/langs/markdown/toc.lua`

The user-facing command is:

```vim
:MarkdownToc
```

The corresponding keymap is:

```text
<leader>mo
```

### 10.3 Marker format

The integration uses:

```markdown
<!-- toc -->

<!-- tocstop -->
```

Both markers are required.

The integration validates that:

- Exactly one opening marker exists.
- Exactly one closing marker exists.
- The opening marker precedes the closing marker.

Invalid marker arrangements must produce actionable errors.

### 10.4 Execution architecture

The integration:

1. Resolves Node.js.
2. Resolves the `markdown-toc` executable.
3. Locates the package entry point.
4. Validates the current buffer.
5. Captures the current buffer content.
6. Writes the content to a temporary file.
7. Runs the TOC generator asynchronously.
8. Reads the generated content.
9. Validates the request and buffer state.
10. Updates the buffer only after successful execution.
11. Cleans up the temporary file.

The implementation supports the maintained `@frat/markdown-toc` package and its package entry-point resolution.

### 10.5 Buffer safety

The command must:

- Use current buffer content, including unsaved changes.
- Avoid automatic saving.
- Preserve the original end-of-line setting.
- Avoid updating the buffer after a failed process.
- Reject stale results.
- Avoid updating invalid or non-modifiable buffers.
- Clean up temporary files.
- Avoid unnecessary buffer updates when the generated content is unchanged.

Repeated execution should be idempotent when the document structure has not changed.

### 10.6 Validation

Verify:

- Package installation.
- Executable discovery.
- Package entry-point resolution.
- Valid marker handling.
- Missing marker handling.
- Duplicate marker handling.
- Invalid marker ordering.
- Unsaved-buffer input.
- Successful buffer updates.
- Idempotency.
- Stale-result handling.
- Temporary-file cleanup.
- Missing dependency behavior.
- Process failure behavior.
- No automatic saving.

## 11. Mermaid Diagram Rendering

### 11.1 Baseline diagram format

Mermaid is the baseline diagram format.

Reference:

https://mermaid.js.org/

Mermaid provides a text-based diagram syntax suitable for Markdown documents.

The dedicated Neovim integration is separate from the default Markdown renderer's internal Mermaid support.

### 11.2 Dedicated rendering command

The implementation is:

`lua/langs/markdown/mermaid.lua`

The user-facing command is:

```vim
:MermaidRender
```

The command is mapped to:

```text
<leader>mr
```

The mapping is buffer-local and is registered for Markdown buffers.

### 11.3 Dedicated workflow

The command:

1. Identifies the Mermaid fenced code block under the cursor.
2. Extracts the diagram source.
3. Resolves the Mermaid CLI executable.
4. Resolves or uses the configured browser.
5. Supplies Puppeteer browser configuration.
6. Runs Mermaid CLI.
7. Generates an SVG.
8. Opens the generated SVG through Neovim's system-opening interface.

The extraction workflow supports backtick and tilde fenced code blocks.

### 11.4 External dependencies

The dedicated workflow requires:

| Dependency | Responsibility |
|---|---|
| Mermaid CLI (`mmdc`) | Converts Mermaid source into SVG |
| Node.js runtime | Executes the Mermaid CLI |
| Puppeteer | Controls browser-based rendering |
| Chrome or Chromium | Provides the browser used for rendering |

Mermaid CLI:

https://github.com/mermaid-js/mermaid-cli

Puppeteer:

https://pptr.dev/

Browser configuration must be explicit and valid.

The implementation supports:

- `CHROME_PATH`
- `CHROMIUM_PATH`
- Puppeteer configuration through `--puppeteerConfigFile`

### 11.5 No automatic installation

The dedicated Lua command must not:

- Install Mermaid CLI.
- Install Node.js.
- Install Chrome or Chromium.
- Use an `npx` installation fallback.
- Silently download missing dependencies.

Missing dependencies must produce actionable diagnostics.

### 11.6 Rendering output

The dedicated workflow generates SVG output.

The Markdown source buffer must remain unchanged.

A failed render must not be reported as a successful diagram generation.

The generated output should be opened through the system opener rather than changing the source document.

### 11.7 Relationship with md-render.nvim

There are two separate Mermaid workflows.

| Workflow | Responsibility |
|---|---|
| `md-render.nvim` | Renders Mermaid diagrams as part of its Markdown preview |
| `:MermaidRender` | Extracts and renders the Mermaid block under the cursor as a standalone SVG |

These workflows must not be conflated.

The no-`npx` rule described above applies to the dedicated Lua integration. It must not be incorrectly attributed to the internal implementation of `md-render.nvim`.

The renderer's own optional dependency and Mermaid behavior must be documented according to its upstream implementation and the features actually selected.

### 11.8 Windows validation record

The reported Windows test environment included:

- Mermaid CLI `12.2.0`.
- Neovim `0.12.6`.
- Chrome at:

```text
C:\Program Files\Google\Chrome\Application\chrome.exe
```

The user confirmed that the configured browser worked with Mermaid CLI and generated SVG output.

The Mermaid Lua integration was also reported as implemented and tested.

Do not infer macOS or Linux compatibility from the Windows validation record.

### 11.9 Validation

Verify:

- Fenced block extraction.
- Backtick and tilde fences.
- Cursor position handling.
- Invalid or missing Mermaid blocks.
- Mermaid CLI discovery.
- Node.js discovery.
- Browser discovery.
- Explicit browser configuration.
- Puppeteer configuration.
- SVG generation.
- System opening.
- Missing dependency diagnostics.
- Invalid diagram diagnostics.
- Process failure handling.
- Request cancellation.
- Timeout behavior.
- Temporary-file cleanup.
- Source-buffer preservation.
- Preservation of previous successful output when a new render fails.

Do not claim that cancellation terminates the entire browser process tree unless that behavior has been independently verified.

## 12. Markdown Rendering

### 12.1 Default renderer

The accepted default renderer is:

`delphinus/md-render.nvim`

Repository:

https://github.com/delphinus/md-render.nvim

The plugin configuration is:

`lua/plugins/md-render.lua`

The plugin is installed through Neovim's native `vim.pack` workflow.

It provides terminal-native Markdown preview functionality.

Preview activation is explicit. The renderer does not start automatically when Neovim starts or when a Markdown buffer opens.

### 12.2 Renderer responsibilities

The renderer owns the visual preview workflow.

Its responsibilities are separate from:

- Marksman language intelligence.
- Tree-sitter syntax parsing.
- Prettier formatting.
- markdownlint diagnostics.
- TOC generation.
- The dedicated Mermaid command.

The renderer's internal implementation must not be duplicated in the Markdown language pack.

### 12.3 Terminal compatibility

The reported target environment includes:

| Component | Tested environment |
|---|---|
| Operating system | Windows |
| Neovim | `0.12.6` |
| Terminal | WezTerm |
| WezTerm version | `20240203-110809-5046fc22` |
| Renderer | `md-render.nvim` |

The user reported successful interactive validation in this environment.

This evidence must not be generalized to every terminal emulator or operating system.

### 12.4 Rendering compatibility contract

The default renderer's regression contract includes:

- CommonMark soft-break behavior.
- Paragraph continuation.
- List-item continuation lines.
- Blockquote continuation lines.
- Nested lists and blockquotes.
- CJK paragraph joining without unintended spaces.
- CJK-aware line wrapping.
- Documented Japanese kinsoku behavior.
- Inline formatting.
- Links and images.
- Fenced code blocks.
- Mermaid rendering as inline images where supported by the renderer.

These requirements should be covered by representative fixtures and interactive tests.

The renderer's actual behavior must be distinguished from the behavior of the dedicated Mermaid command.

### 12.5 Optional dependencies

Optional rendering features may require additional external tools or terminal capabilities.

Potential feature-specific dependencies include:

- Terminal graphics support.
- Mermaid CLI and browser rendering dependencies.
- D2.
- archDraw.
- BudouX.
- FFmpeg and ffprobe.
- ImageMagick.

Do not treat this list as a universal mandatory installation set.

Each dependency must be tied to a specific feature and verified against the renderer's actual requirements.

Basic Markdown editing must not depend on optional rendering tools.

### 12.6 Default renderer mappings

The current mappings are defined in:

`lua/config/keymaps.lua`

| Mapping | Description |
|---|---|
| `<leader>mp` | Toggle the `md-render.nvim` preview |
| `<leader>mt` | Toggle the `md-render.nvim` preview in a tab |
| `<leader>md` | Open the `md-render.nvim` demo |

These mappings use the default renderer's documented `<Plug>` interfaces.

They do not imply automatic preview activation and must not be reassigned to an optional renderer.

### 12.7 Optional alternative in-buffer renderer

`render-markdown.nvim` is retained as an optional alternative.

Repository:

https://github.com/MeanderingProgrammer/render-markdown.nvim

It is an in-buffer renderer, not the accepted default.

It does not have a default plugin configuration module in the current repository.

If it is evaluated or selected later, its configuration must remain independent of the existing `md-render.nvim` configuration.

Its dependencies, rendering behavior, compatibility, and mappings must be documented separately. It must not silently replace the accepted default renderer.

### 12.8 Optional browser-preview extension

`markdown-preview.nvim` is an optional browser-based preview extension.

Repository:

https://github.com/iamcco/markdown-preview.nvim

It provides a separate preview workflow that serves the Markdown document for viewing in an external browser. It is distinct from both the terminal-native `md-render.nvim` renderer and the in-buffer `render-markdown.nvim` alternative.

Its architectural status is:

- Optional; not part of the default installation.
- Not currently configured or enabled in the repository.
- Not recorded as an installed plugin or lockfile entry.
- Not required for ordinary Markdown editing.
- Not a replacement for `md-render.nvim`.
- Not a dependency of the dedicated `:MermaidRender` command.

If adopted, it must have an independent plugin specification and independently chosen keymaps. Its browser launch behavior, local preview server lifecycle, supported Markdown extensions, external dependencies, and security implications must be reviewed against the upstream implementation. Browser preview must remain an explicit user action; it must not launch automatically when Neovim starts or when a Markdown buffer opens.

Do not reuse the existing `<leader>mp`, `<leader>mt`, or `<leader>md` mappings without a separate keymap review. Those mappings belong to the accepted `md-render.nvim` workflow.

Documenting this optional candidate records an architectural option. It does not authorize installing it, adding it to `vim.pack`, changing the lockfile, or implementing its configuration.

## 13. Intended Markdown Workflow

### 13.1 Ordinary editing

Open a Markdown document and use:

- Native Neovim editing.
- Tree-sitter highlighting.
- Marksman language intelligence.
- Local wrapping and spell checking.

Ordinary Markdown editing must work without a preview plugin or diagram renderer.

### 13.2 Formatting

Run:

```vim
:Format
```

Prettier is selected through the shared formatter infrastructure.

Formatting is manual by default.

### 13.3 Linting

Run:

```vim
:MarkdownLint
```

The command checks the current buffer, including unsaved content, and publishes diagnostics.

### 13.4 Table of contents

Add the TOC markers:

```markdown
<!-- toc -->

<!-- tocstop -->
```

Then run:

```vim
:MarkdownToc
```

The command updates the current buffer after successful generation.

### 13.5 Mermaid rendering

Place the cursor inside a Mermaid fenced code block and run:

```vim
:MermaidRender
```

The command generates an SVG and opens it externally.

### 13.6 Default terminal preview

Use:

```text
<leader>mp
```

to toggle the `md-render.nvim` preview.

Use:

```text
<leader>mt
```

to toggle the preview in a tab.

Use:

```text
<leader>md
```

to open the renderer's demo.

Preview remains an explicit action.

### 13.7 Optional browser preview

`markdown-preview.nvim` is a separate, opt-in browser-preview workflow. It is not currently configured, so this document does not assign it a keymap or claim that it can be invoked in the current setup.

If the plugin is adopted later, document its explicit start, refresh, and stop workflow alongside its independent keymaps. Starting a browser preview must remain a user action, and the workflow must not interfere with `md-render.nvim`.

## 14. Dependencies and External Tool Management

### 14.1 Dependency classification

| Dependency | Type | Required capability |
|---|---|---|
| Marksman | External executable | Markdown language intelligence |
| Prettier | External executable and Node.js runtime | Markdown formatting |
| Node.js | External runtime | Markdown CLI integrations |
| `markdownlint-cli2` | External Node.js package | Markdown linting |
| `@frat/markdown-toc` | External Node.js package | TOC generation |
| Mermaid CLI | External Node.js package | Dedicated Mermaid rendering |
| Chrome or Chromium | External browser | Mermaid browser rendering |
| Tree-sitter Markdown parsers | Parser binaries | Syntax parsing and highlighting |
| `md-render.nvim` | Neovim plugin | Default terminal-native Markdown preview |
| `render-markdown.nvim` | Optional Neovim plugin | Alternative in-buffer rendering |
| `markdown-preview.nvim` | Optional Neovim plugin | Browser-based Markdown preview |

D2, archDraw, BudouX, FFmpeg, ffprobe, and ImageMagick are feature-specific optional dependencies.

### 14.2 Windows dependency script

The Markdown dependency script is:

`scripts/core/windows/markdown-deps.ps1`

It checks and optionally installs two global Node.js packages:

- `markdownlint-cli2`
- `@frat/markdown-toc`

The default mode checks availability.

The explicit installation mode is:

```powershell
.\scripts\core\windows\markdown-deps.ps1 -InstallMissing
```

The script:

- Checks the required executables.
- Checks tool versions.
- Uses npm for explicit installation.
- Installs missing packages.
- Verifies the installed executables.
- Uses npm's global prefix to refresh the current process's `PATH` when necessary.
- Does not modify persistent Windows `PATH` settings.

Node.js and npm must already be installed when installation is requested.

The script does not install:

- Node.js or npm.
- Marksman.
- Prettier.
- Mermaid CLI.
- Chrome or Chromium.
- Neovim plugins.
- Tree-sitter parsers.
- D2.
- archDraw.
- BudouX.

### 14.3 Installation policy

External tools remain outside Neovim's plugin configuration.

The configuration must not silently install missing executables.

Use the project's operating-system and tool-management workflows to install and update external dependencies.

The Windows Markdown script is deliberately limited to the two Markdown CLI packages it manages.

### 14.4 Version and environment documentation

Record versions when they materially affect compatibility.

Distinguish:

- Verified versions.
- Minimum supported versions.
- Optional dependency versions.
- Untested platform combinations.

Do not treat a successful executable lookup as proof that every dependent feature works.

For example, finding `mmdc` does not prove that Puppeteer can launch the configured browser.

## 15. Testing and Validation

### 15.1 Validation principles

Validation must distinguish implementation correctness from environment availability and interactive behavior.

A successful module load does not prove that an external executable is installed.

A successful executable lookup does not prove that the tool works.

A successful parser installation does not prove that the renderer handles every syntax feature.

A successful LSP configuration does not prove that the server attaches to the intended buffer.

### 15.2 Automated checks

Use the repository's existing syntax, smoke, and language-pack test infrastructure.

Verify:

- Markdown pack discovery and activation.
- Parser metadata.
- Primary and additional parser registration.
- Formatter metadata collection.
- Formatter selection.
- LSP configuration.
- Lint command registration.
- Lint configuration validation.
- Structured diagnostic output.
- TOC command registration.
- TOC execution and buffer updates.
- Mermaid command registration.
- Mermaid block extraction.
- Asynchronous request handling.
- Stale-result protection.
- Error handling.
- Temporary-file cleanup.
- Windows dependency script behavior.

Do not create a parallel validation framework when an existing shared test interface can validate the same contract.

### 15.3 Markdown fixtures

Maintain separate fixture groups.

**CommonMark**

- Headings.
- Paragraphs.
- Soft and hard breaks.
- Lists.
- List-item continuation.
- Blockquotes.
- Blockquote continuation.
- Nested structures.
- Code blocks.
- Links and images.
- Inline formatting.
- Autolinks.
- Raw HTML.
- Escapes and character references.

**GFM**

- Tables.
- Task lists.
- Strikethrough.
- Bare URL autolinks.
- Bare email autolinks.
- Raw HTML filtering.

**CJK**

- Japanese paragraphs.
- Simplified Chinese paragraphs.
- Traditional Chinese paragraphs.
- Mixed CJK and Latin text.
- Soft breaks.
- Paragraph boundaries.
- Punctuation.
- Kinsoku cases.
- Narrow display widths.

**Linting**

- Valid documents.
- Deliberate rule violations.
- Project rule overrides.
- Invalid project configuration.
- Unsupported configuration formats.

**Rendering**

- Paragraphs and soft breaks.
- Nested lists.
- Blockquotes.
- Tables.
- Links and images.
- Fenced code blocks.
- Mermaid.
- CJK text.
- Mixed CJK and Latin text.
- Terminal resizing.

**MDX**

Maintain separate MDX fixtures under the MDX specification.

### 15.4 Interactive checks

Verify:

- Marksman starts and attaches to Markdown buffers.
- Prettier formats documents through `:Format`.
- `:MarkdownLint` reports expected diagnostics.
- `:MarkdownToc` updates unsaved buffer content.
- Markdown and inline Markdown highlighting work.
- `md-render.nvim` renders documents in the target terminal.
- Mermaid diagrams render through the preview workflow where supported.
- `:MermaidRender` extracts the correct fenced block.
- SVG output opens through the system opener.
- Invalid Mermaid source produces actionable errors.
- Missing dependencies produce actionable diagnostics.
- Preview activation remains manual.
- Optional in-buffer renderer behavior remains independent.
- If `markdown-preview.nvim` is adopted, its browser launch, preview-server lifecycle, buffer refresh, stop behavior, and failure handling are tested independently.
- CJK joining, wrapping, and kinsoku behavior match the documented regression contract.

### 15.5 Reported validation record

The following implementation and verification work has been reported as completed:

- Markdown language-pack implementation.
- Centralized language-pack activation.
- Markdown parser mapping.
- `markdown` and `markdown_inline` parser installation and use.
- Markdown syntax highlighting and fenced-code parsing.
- Marksman native LSP configuration and attachment.
- Prettier installation and formatting verification.
- `markdownlint-cli2` configuration and custom JSON formatter.
- Markdown lint integration through `:MarkdownLint`.
- Named-buffer project root discovery.
- Project root discovery when Neovim's working directory is outside the repository.
- Unsaved-buffer linting.
- Diagnostic publication.
- Stale-result handling.
- Malformed output handling.
- Missing dependency handling.
- TOC CLI installation and generation.
- TOC idempotency.
- Neovim TOC integration.
- Mermaid block extraction.
- Mermaid CLI installation and verification.
- Explicit Puppeteer browser configuration.
- SVG generation using Chrome on Windows.
- `md-render.nvim` interactive validation on Windows with WezTerm.
- Default renderer acceptance.
- Windows Markdown dependency script testing.
- Manual preview mappings.
- Manual command-based workflow.

The reported environment included:

- Neovim `0.12.6`.
- WezTerm `20240203-110809-5046fc22`.
- Mermaid CLI `12.2.0`.
- Chrome at `C:\Program Files\Google\Chrome\Application\chrome.exe`.
- `@frat/markdown-toc` `1.3.0`.

These are reported validation results, not a claim that every check was rerun during this document revision.

### 15.6 Compatibility regression work

Keep the following compatibility cases in the active regression scope:

1. CommonMark soft-break handling.
2. Paragraph continuation inside list items.
3. Paragraph continuation inside blockquotes.
4. CJK-aware paragraph joining without unintended spaces.
5. CJK-aware line wrapping.
6. Japanese kinsoku behavior.
7. Mixed CJK and Latin text.
8. Marksman behavior on representative Markdown documents.

For each case, retain a reproducible fixture and a clearly defined expected result.

Do not mark a case as passing solely because the plugin loads or a preview opens.

The current compatibility exploration should continue as maintenance work without changing the completed Stage 13 status.

### 15.7 Platform coverage

The reported interactive validation primarily covers Windows with Neovim and WezTerm.

Do not claim macOS or Linux rendering compatibility until the relevant workflows have been tested on those platforms.

Keep platform-specific dependencies and limitations documented separately.

### 15.8 Failure behavior

Tests must distinguish missing optional dependencies from broken core configuration.

Examples:

- Missing Marksman must not be reported as successful server startup.
- Missing Prettier must produce actionable formatting feedback.
- Missing `markdownlint-cli2` must produce an actionable linting error.
- Invalid project lint configuration must stop lint execution and explain the problem.
- Missing Node.js must prevent Node-based CLI execution.
- Missing Mermaid CLI must produce an actionable error.
- Missing or invalid browser configuration must be reported.
- Mermaid rendering failure must not modify the Markdown source.
- Stale asynchronous results must not overwrite newer buffer state.
- Missing optional rendering dependencies must not prevent ordinary Markdown editing.

## 16. Documentation Requirements

### 16.1 `docs/architecture/markdown-linting.md`

Keep linting-specific architecture and implementation details in the dedicated linting document.

It should describe:

- The HETFS lint baseline.
- Project-level rule overrides.
- Configuration validation.
- Structured JSON diagnostics.
- Neovim integration.
- Error handling.
- Testing.

The Markdown support document should summarize linting responsibilities without duplicating the entire linting specification.

### 16.2 `docs/architecture/mdx-support.md`

Keep MDX separate from Markdown.

MDX has its own:

- Language pack.
- Language server.
- Formatter.
- Parser.
- Dependencies.
- Configuration.
- Compatibility requirements.

Markdown plugins must not be assumed to provide complete MDX support.

### 16.3 `docs/architecture/plugin-inventory.md`

Keep plugin admission and dependency decisions synchronized with the implementation.

Record:

- `md-render.nvim` as the accepted default terminal renderer.
- `render-markdown.nvim` as an optional in-buffer alternative.
- `markdown-preview.nvim` as an optional browser-preview extension, not currently configured or installed.
- Exact plugin revisions where recorded.
- Relevant compatibility evidence.
- The separation between Neovim plugins and external executables.

Do not list an optional candidate as installed or accepted merely because it appears in this document.

### 16.4 Dependency documentation

Keep external installation and verification instructions synchronized with:

- `scripts/core/windows/markdown-deps.ps1`.
- Marksman.
- Prettier.
- Node.js and npm.
- `markdownlint-cli2`.
- `@frat/markdown-toc`.
- Mermaid CLI.
- Chrome or Chromium.
- Tree-sitter parser requirements.
- Optional renderer dependencies.

Document only verified platform-specific requirements.

### 16.5 Roadmap

Stage 13 remains complete.

Do not reopen the stage because of ongoing compatibility regression work.

Future Markdown changes should follow the current project roadmap and introduce a new implementation stage only when the scope justifies it.

## 17. Maintenance Priorities

The implementation is complete, but its dependencies and compatibility requirements need ongoing maintenance.

Priorities:

1. Preserve the current Markdown language-pack architecture.
2. Keep shared parser and formatter metadata valid.
3. Retain Marksman attachment regression checks.
4. Retain Prettier formatting regression checks.
5. Retain lint configuration and diagnostic regression checks.
6. Retain TOC generation and buffer-safety regression checks.
7. Retain Mermaid process and output-safety regression checks.
8. Maintain `md-render.nvim` compatibility fixtures.
9. Continue CommonMark and GFM regression coverage.
10. Continue CJK paragraph, wrapping, and kinsoku regression coverage.
11. Keep optional dependencies separate from the core workflow.
12. Keep supporting documentation aligned with verified implementation changes.

Avoid introducing new dependencies without a demonstrated requirement.

Do not replace an accepted component merely because an alternative offers additional features. Evaluate alternatives against the current requirements, compatibility evidence, dependency cost, and maintenance burden.

## 18. Acceptance and Maintenance Criteria

### 18.1 Core Markdown support

**Status: Complete.**

The core Markdown language-pack implementation provides:

- Centralized activation.
- Tree-sitter parser metadata.
- Marksman native LSP integration.
- Prettier formatting through Conform.
- `markdownlint-cli2` integration.
- TOC generation.
- Dedicated Mermaid rendering.
- Explicit dependency management.
- Manual user-facing workflows.

The completed status is preserved unless a regression or architectural change requires reopening a specific implementation.

### 18.2 Default renderer

**Status: Accepted.**

`md-render.nvim` is the default in-editor renderer.

Its acceptance is based on the reported Windows and WezTerm validation.

Its ongoing regression contract includes:

- CommonMark soft breaks.
- List continuation.
- Blockquote continuation.
- CJK paragraph joining.
- CJK line wrapping.
- Japanese kinsoku behavior.
- Inline Mermaid rendering where supported.
- Explicit preview activation.
- No silent dependency installation.

### 18.3 Dedicated Mermaid workflow

**Status: Implemented.**

The dedicated `:MermaidRender` command provides standalone SVG rendering.

Its maintenance contract includes:

- Correct fenced-block extraction.
- Explicit executable and browser discovery.
- Puppeteer configuration.
- SVG generation.
- System opening.
- Source-buffer preservation.
- Actionable failure reporting.
- Request lifecycle and cleanup safety.

The dedicated command and the renderer's internal Mermaid workflow remain separate.

### 18.4 Linting

**Status: Implemented.**

The linting integration provides:

- A HETFS baseline.
- Validated project-level rule overrides.
- Structured JSON diagnostics.
- Unsaved-buffer input.
- Asynchronous execution.
- Stale-result protection.
- Explicit manual invocation.

### 18.5 TOC generation

**Status: Implemented.**

The TOC integration provides:

- Explicit marker validation.
- Current-buffer input.
- Asynchronous execution.
- Safe buffer updates.
- Idempotent generation.
- Temporary-file cleanup.
- No automatic saving.

### 18.6 Optional rendering plugins

**Status: Optional.**

Two independent alternatives are documented:

- `render-markdown.nvim` is an optional in-buffer renderer.
- `markdown-preview.nvim` is an optional browser-preview extension and is not currently configured or installed.

Neither replaces the accepted `md-render.nvim` baseline. Any future adoption must document the plugin revision, dependencies, compatibility, configuration, keymaps, lifecycle behavior, and impact on the existing renderer. Adding either plugin to the active configuration or lockfile requires a separate implementation decision.

### 18.7 Optional diagram formats

**Status: Optional.**

D2 and archDraw must remain independent of the baseline Mermaid workflow.

Their admission requires demonstrated requirements, explicit dependency management, compatibility validation, and a documented decision.

### 18.8 Compatibility maintenance

**Status: Ongoing regression work.**

CommonMark, list continuation, blockquote continuation, CJK paragraph joining, CJK wrapping, and kinsoku behavior remain explicit maintenance requirements.

Ongoing regression testing does not change the completed Stage 13 status.

## 19. References

### Markdown specifications

- CommonMark: https://spec.commonmark.org/current/
- GitHub Flavored Markdown: https://github.github.com/gfm/
- cmark: https://github.com/commonmark/cmark

### Language intelligence and formatting

- Marksman: https://github.com/artempyanykh/marksman
- Prettier: https://prettier.io/docs
- markdownlint-cli2: https://github.com/DavidAnson/markdownlint-cli2
- markdownlint-cli2 configuration schema: https://github.com/DavidAnson/markdownlint-cli2/blob/main/schema/markdownlint-cli2-config-schema.json

### Table of contents

- `@frat/markdown-toc`: https://www.npmjs.com/package/@frat/markdown-toc

### Rendering

- md-render.nvim: https://github.com/delphinus/md-render.nvim
- render-markdown.nvim: https://github.com/MeanderingProgrammer/render-markdown.nvim
- markdown-preview.nvim: https://github.com/iamcco/markdown-preview.nvim

### Diagram tooling

- Mermaid: https://mermaid.js.org/
- Mermaid CLI: https://github.com/mermaid-js/mermaid-cli
- Puppeteer: https://pptr.dev/
- D2: https://d2lang.com/

### Related project documentation

- Markdown linting: `docs/architecture/markdown-linting.md`
- MDX support: `docs/architecture/mdx-support.md`
- Plugin inventory: `docs/architecture/plugin-inventory.md`
- Dependencies: `docs/architecture/dependencies.md`
- Roadmap: `docs/architecture/roadmap.md`

---

> **Approval is not installation.** Every component must earn its place through a defined responsibility, documented dependency, and reproducible validation.
