# Markdown Support

## Purpose

Define the implementation, dependency, workflow, and validation
requirements for Markdown authoring in `nvim-config`.

Markdown is part of Stage 13 because project documentation is an
important development workflow. The design combines focused tools with
distinct responsibilities rather than relying on one plugin to provide
language intelligence, formatting, linting, syntax highlighting, and
visual rendering.

> **Minimum installation. Compose the rest.**

## Status

-   **Stage:** 13 --- Language Packs
-   **Document status:** Active implementation and validation record
-   **Core implementation status:** In progress
-   **Language pack:** Implemented in `lua/langs/markdown.lua`
-   **Marksman:** Declared and conditionally enabled; interactive LSP
    attachment verification remains outstanding
-   **Prettier:** Declared as the Markdown formatter; interactive
    `:Format` verification remains outstanding
-   **Tree-sitter:** `markdown` and `markdown_inline` parser
    registration and loading verified
-   **Markdown linting:** Integrated; CLI, JSON formatter, configuration
    loading, and `:MarkdownLint` workflow verified
-   **Markdown TOC generation:** `@frat/markdown-toc` v1.3.0 installed
    globally; CLI generation and idempotency verified in PowerShell. The
    Neovim `:MarkdownToc` integration still requires interactive
    validation.
-   **Markdown CLI dependency script:**
    `scripts/core/windows/markdown-deps.ps1` is the selected management
    entrypoint for `markdownlint-cli2` and `markdown-toc`. The proposed
    check/install behavior is documented below; Windows execution and
    validation remain outstanding.
-   **Default preview:** `delphinus/md-render.nvim`; Windows + WezTerm
    validation passed and baseline accepted
-   **Optional preview:** `sammaji/markdown-preview.nvim`; isolated
    evaluation remains outstanding
-   **Plugin admission:** `md-render.nvim` is accepted for the default
    baseline; the browser preview remains opt-in and unevaluated

Stages 04, 10, and 12 are complete. They are not outstanding
prerequisites for Markdown implementation and must not be treated as
implementation blockers.

A configured component is not automatically an installed dependency or a
verified workflow. Markdown support must not be marked complete until
its required implementation, dependency documentation, automated checks,
and interactive validation have passed.

The preview installation policy is established:

-   `md-render.nvim` is the default baseline preview.
-   `markdown-preview.nvim` is an optional extension.
-   Both remain independently configured and user-activated.
-   Neither preview starts automatically during Neovim startup or when a
    Markdown buffer opens.
-   The baseline preview must pass the target Windows + WezTerm
    compatibility evaluation before it is admitted to the active plugin
    inventory.

## Design Principles

-   Prefer Neovim's built-in capabilities where they adequately satisfy
    the requirement.
-   Separate language-server configuration, formatting, linting, syntax
    highlighting, and visual rendering.
-   Use Neovim's native `vim.pack` workflow for explicitly admitted
    plugins.
-   Keep external executables separate from plugin installation.
-   Follow the existing language-pack architecture and centralized user
    configuration.
-   Preserve the manual formatting contract: no format-on-save and no
    LSP formatting fallback by default.
-   Keep linting independent of formatting, even though both are
    included in the current implementation scope.
-   Keep rendering independent of the core Markdown editing workflow.
-   Reuse existing shared LSP, formatter, language registry, and
    validation infrastructure.
-   Distinguish a proposed tool from an admitted dependency and a
    configured component from a verified workflow.
-   Do not introduce a new plugin when an existing executable and shared
    infrastructure can provide the required functionality.
-   Keep the two preview implementations independent. Neither must
    depend on the other.
-   Do not silently download external executables, renderer binaries, or
    packages.
-   Keep preview activation under explicit user control.

## Component Responsibilities and Status

  -----------------------------------------------------------------------
  Component                 Responsibility         Status
  ------------------------- ---------------------- ----------------------
  Tree-sitter               Markdown syntax        `markdown` and
                            parsing and            `markdown_inline`
                            highlighting           parsers verified

  Marksman                  Markdown               Declared and
                            language-server        conditionally enabled;
                            features, including    runtime attachment
                            link navigation,       verification
                            completion,            outstanding
                            references, and        
                            diagnostics            

  Prettier                  Markdown source        Declared in formatter
                            formatting             metadata; interactive
                                                   `:Format` verification
                                                   outstanding

  `markdownlint-cli2`       Markdown style and     Integrated and
                            consistency linting    interactively verified
                                                   through
                                                   `:MarkdownLint`

  `markdown-toc`            On-demand TOC          CLI verified; Neovim
                            generation             integration pending
                                                   validation

  `md-render.nvim`          In-editor Markdown     Default baseline;
                            rendering, diagrams,   Windows + WezTerm
                            CommonMark behavior,   validation passed;
                            and CJK-aware          accepted
                            rendering              

  `markdown-preview.nvim`   Browser-based Markdown Optional extension;
                            preview with live      isolated evaluation
                            updates                not started
  -----------------------------------------------------------------------

These components are complementary, not interchangeable.

Marksman provides language intelligence rather than visual rendering.
Prettier formats source text rather than displaying a preview.
`markdownlint-cli2` checks Markdown rules rather than replacing the
formatter. Tree-sitter provides syntax parsing and highlighting, not a
complete rendered preview.

The core Markdown editing workflow must remain usable without either
preview plugin. TOC generation is an explicit command and is independent
of preview rendering.

## 1. Language-Pack Architecture

Markdown support follows the existing language-pack architecture.

### Core pack

The Markdown language pack lives in:

`lua/langs/markdown.lua`

The current pack declares:

-   `formatters`: the default formatter for Markdown.
-   `parser_by_filetype`: the primary parser for the Markdown filetype.
-   `parser_dependencies_by_filetype`: additional parsers required by
    Markdown.

The pack declares only metadata consumed by the existing shared
infrastructure:

  Metadata            Markdown value
  ------------------- -------------------
  Primary parser      `markdown`
  Parser dependency   `markdown_inline`
  Formatter           `prettier`

Marksman, linting, and TOC generation are initialized by the pack's
explicit `setup()` implementation. Their executable checks remain within
their respective integration modules. Do not add `servers` or
`executables` metadata unless a shared consumer is implemented and
validated.

`markdown-toc` is an approved external CLI dependency for the explicit
TOC workflow described in Section 6. It is resolved by
`lua/langs/markdown/toc.lua`; it is not installed by Neovim or by the
language registry.

The language registry discovers and initializes the pack. The pack must
not independently install plugins or external executables, introduce a
separate loader, or duplicate shared formatter infrastructure.

### Shared infrastructure

Reuse the existing infrastructure for:

-   Discovering and enabling language packs.
-   Registering and enabling language servers through Neovim's native
    LSP APIs.
-   Collecting formatter and parser metadata.
-   Resolving user-preferred and exclusive formatters where supported.
-   Reporting missing external executables.
-   Validating metadata and configuration.
-   Preserving existing startup and error-handling behavior.

Do not introduce a separate Markdown-specific loader, formatter
framework, or configuration path.

### User configuration

User-facing language configuration belongs in:

`lua/config/languages.lua`

The Markdown pack is enabled through this centralized configuration.
Formatter preferences and exclusive formatter selections must use the
existing configuration fields rather than a Markdown-only preference
mechanism.

Lint configuration must also have a clear ownership boundary. Reuse the
repository's existing configuration conventions and avoid introducing an
independent configuration system solely for Markdown.

### Preview components

Preview plugins are separate from the core language pack.

-   The baseline profile includes the accepted `md-render.nvim` plugin.
-   `markdown-preview.nvim` is available as an explicitly selected
    optional extension.
-   Each plugin has its own configuration module and activation
    commands.
-   Installing or configuring one plugin must not install, configure, or
    activate the other.
-   A missing or broken preview dependency must not prevent ordinary
    Markdown editing, language-server support, formatting, or linting.

## 2. Tree-sitter Integration

Tree-sitter provides Markdown syntax parsing and highlighting through
the existing `lua/plugins/treesitter.lua` integration.

### Parser metadata

Language packs declare primary parser mappings through
`parser_by_filetype` and additional parser requirements through
`parser_dependencies_by_filetype`.

The Markdown pack declares:

-   Primary parser: `markdown`
-   Additional parser: `markdown_inline`

The Tree-sitter integration collects both metadata fields from enabled
language packs. It validates the mappings and dependency lists before
registering its `FileType` autocmd.

The primary parser is installed and started for highlighting. Additional
parsers are installed as dependencies without being started as the
buffer's primary parser.

### Installation behavior

The integration:

-   Reuses an available parser.
-   Requests installation of a missing parser through `nvim-treesitter`.
-   Tracks pending installations to avoid duplicate requests.
-   Associates waiting buffers with the parser being installed.
-   Starts highlighting only for buffers that requested the parser as
    their primary parser.
-   Checks that a buffer is still valid and still has the expected
    filetype before starting highlighting.
-   Reports installation and highlighting failures through Neovim
    notifications.

Parser installation is asynchronous. A dependency installation must not
start that dependency as the buffer's primary parser.

### Validation

Verify that:

1.  Markdown files receive the expected `markdown` filetype.
2.  Both `markdown` and `markdown_inline` parsers are available and load
    successfully.
3.  Missing parsers are installed through the existing asynchronous
    installation path.
4.  Primary-parser highlighting starts for Markdown buffers.
5.  Additional parser dependencies are installed without being started
    as primary parsers.
6.  Invalid parser metadata fails clearly.
7.  Existing Windows compiler and archive-tool setup remains intact.

A passing configuration smoke test alone does not prove that every
parser is installed or that highlighting is correct. Retain interactive
checks for visible highlighting behavior.

Do not install another Markdown syntax-highlighting plugin to duplicate
the existing Tree-sitter responsibility without a demonstrated
requirement and a separate admission decision.

## 3. Markdown Language Server

**Implementation target:** Marksman.

Marksman provides Markdown language intelligence, including supported
link completion, navigation, references, and diagnostics.

The Markdown pack declares the Marksman server and its executable. Its
setup checks whether the executable is available before enabling the
server through Neovim's native LSP API.

### Implementation requirements

-   Keep Marksman activation within the Markdown language pack.
-   Use the existing native LSP architecture and server definitions.
-   Configure and activate the server through Neovim's native LSP APIs.
-   Keep the Marksman executable independently managed from plugin
    installation.
-   Verify the server identifier and definition against the installed
    server configuration.
-   Verify behavior on individual Markdown files and within a project
    workspace.
-   Test internal links, heading navigation, references, and diagnostics
    where applicable.
-   Document verified installation and executable requirements in
    `docs/dependencies.md`.
-   Ensure a missing executable is distinguishable from successful
    server startup.

Marksman's project-wide features may depend on workspace-root detection,
repository context, or a `.marksman.toml` marker. Verify the behavior in
the actual configuration instead of assuming that every Markdown file
has the same workspace context.

Do not introduce a second project-root detection mechanism solely for
Markdown. Reuse existing root-detection behavior where compatible and
document any verified Marksman-specific requirements.

### Marksman validation

Verify that:

1.  The Marksman server definition is available.
2.  The executable is detected correctly.
3.  The server starts and attaches when its executable and configuration
    are available.
4.  A missing executable is reported clearly and is not misrepresented
    as successful startup.
5.  Link navigation and other supported features work in a
    representative Markdown project.
6.  Opening an individual Markdown file and opening a file inside a
    project produce understandable behavior.
7.  Workspace-root behavior is tested rather than inferred from the
    presence of a server definition.
8.  Existing LSP behavior and language packs remain unaffected.

Automated checks should validate the configuration contract without
requiring a live server process. Interactive verification must establish
actual server startup and attachment.

## 4. Markdown Formatting

**Formatter:** Prettier.

Formatting uses the existing manual formatting interface through
`:Format` and Conform.

### Formatter requirements

-   Register Prettier through the Markdown language pack's formatter
    metadata.
-   Preserve the existing formatter-resolution contract.
-   Validate user-preferred and exclusive formatter overrides through
    the shared configuration system.
-   Report unavailable formatter executables clearly.
-   Keep format-on-save disabled by default.
-   Keep LSP formatting fallback disabled by default.
-   Keep formatting independent of linting and preview rendering.
-   Keep formatter installation and runtime requirements separate from
    Neovim plugin installation.

Do not introduce a separate Markdown-only formatter preference
mechanism.

### Formatter validation

Format representative Markdown documents containing:

-   Headings and paragraphs.
-   Ordered and unordered lists.
-   Tables.
-   Inline links and reference links.
-   Fenced code blocks.
-   Inline code and emphasis.
-   Long paragraphs and nested content.

Confirm that `:Format` invokes the intended formatter, produces expected
output, and reports unavailable executables clearly.

Also verify that:

-   Formatting remains an explicit user action.
-   Format-on-save has not been enabled inadvertently.
-   LSP formatting is not silently used as a fallback.
-   Formatter selection respects the shared configuration contract.
-   Other filetypes retain their existing formatter behavior.

Prettier documentation: https://prettier.io/docs

## 5. Markdown Linting

**Linter:** `markdownlint-cli2`.

Linting is part of the current Stage 13 Markdown implementation. It is
not deferred to a separate future stage or review.

Linting and formatting remain separate operations with separate
responsibilities:

-   Prettier formats source text.
-   `markdownlint-cli2` checks Markdown against an explicit rule policy.

The linter must use the existing external-tool and language-pack
conventions. A dedicated Neovim lint plugin is not required unless the
existing infrastructure cannot provide the necessary workflow.

### Implementation requirements

-   Use `markdownlint-cli2` as the Markdown lint executable.
-   Keep its installation independent of Neovim plugin installation.
-   Define the lint command and its invocation in the existing tooling
    architecture.
-   Decide and document configuration ownership and rule policy.
-   Report lint findings with useful file and line information.
-   Distinguish rule violations from executable failures and invalid
    configuration.
-   Report a missing executable clearly.
-   Support checking the current Markdown file and, where practical, a
    project-level set of Markdown files.
-   Keep linting independent of `:Format`.
-   Do not silently run linting on save unless a separate explicit
    configuration decision authorizes it.
-   Do not make the linter a prerequisite for opening or editing
    Markdown files.

### Configuration policy

Use the repository's established configuration conventions. Do not
introduce a separate Markdown-only preference system or duplicate shared
tool management.

The lint rule configuration must be version-controlled and documented.
Rule changes must be intentional and validated against representative
Markdown fixtures.

### Lint validation

**Implementation and interactive validation passed.** The current
integration uses stdin so unsaved buffer contents are linted, emits
structured JSON through the custom formatter, and publishes results
through `vim.diagnostic`.

Verified during the current validation:

-   The `markdownlint-cli2` command shim produced valid JSON (`[]`) for
    a clean input, with exit code `0` and empty stderr.
-   Direct execution through the Node.js CLI entrypoint produced the
    same result.
-   The custom formatter and `.markdownlint-cli2.yaml` configuration
    were loaded successfully in both direct CLI tests.
-   The Neovim `:MarkdownLint` command passed for a named Markdown
    buffer.
-   Project-root discovery found the repository configuration even when
    Neovim's working directory was outside the repository.
-   The integration accepts exit code `1` for lint findings and
    distinguishes execution failures from lint results.
-   Unsaved-buffer input, diagnostic publication, stale-result handling,
    malformed JSON, and missing-dependency paths were exercised in the
    earlier integration tests.

An unnamed buffer has no file path from which to discover a repository
root. In that case the current implementation falls back to Neovim's
working directory. A more explicit unnamed-buffer root policy is a
follow-up improvement, not a blocker for the verified named-file
workflow.

Retain representative fixtures covering:

-   A valid Markdown document.
-   Heading hierarchy violations.
-   List formatting violations.
-   Trailing whitespace and blank-line violations.
-   Link and code-block formatting.
-   Rule exceptions that are explicitly documented by the project.

The completed integration checks establish the command and formatter
contract. Continue to retain or add fixture-level checks for:

1.  Valid fixtures passing.
2.  Deliberately invalid fixtures producing expected diagnostics.
3.  Useful file and line information.
4.  Actionable missing-executable errors.
5.  Clear invalid-configuration errors.
6.  Source files remaining unchanged by linting.
7.  Independent formatting and linting operations.
8.  No regressions in other language packs and tooling.

Do not assume that Prettier resolves every lint rule. Where formatter
and linter rules overlap, document the intended policy and verify that
the two tools do not produce an endless formatting/linting cycle.

## 6. Markdown Table of Contents

**CLI:** `@frat/markdown-toc` v1.3.0 (executable: `markdown-toc`).

TOC generation is part of the default Markdown language-pack workflow.
It is implemented in `lua/langs/markdown/toc.lua` and exposed through
the explicit `:MarkdownToc` user command. The Markdown pack initializes
the module through its existing `setup()` function.

### Behavior and ownership

-   Operates on the current Markdown buffer, including unsaved changes.
-   Uses `<!-- toc -->` and `<!-- tocstop -->` as TOC boundaries.
-   Runs the CLI against a temporary Markdown file rather than allowing
    the CLI to modify the source file directly.
-   Updates the buffer only after successful CLI execution.
-   Does not save the buffer automatically.
-   Does not generate or update a TOC on startup, buffer entry, or save.
-   Does not install Node.js packages or other dependencies
    automatically.
-   Reports missing executables, invalid markers, and process failures
    through Neovim notifications.
-   Rejects stale asynchronous results rather than overwriting edits
    made while generation is running.
-   Keeps TOC generation independent of linting, formatting, LSP, and
    preview rendering.

The module resolves `node` and `markdown-toc` through Neovim's PATH,
then locates the Node entrypoint from the npm global package layout. It
supports the original `markdown-toc` package and the maintained
`@frat/markdown-toc` fork. Verify package resolution from inside Neovim
on the target Windows environment.

### Dependency and CLI validation

The selected package is `@frat/markdown-toc`. It was installed globally
using:

``` powershell
npm install --global @frat/markdown-toc
```

The executable reported version `v1.3.0` in PowerShell. Its help output
confirmed file input, stdin input, and `-i` in-place marker-based
generation.

A temporary-file test confirmed that the CLI generated a nested TOC
between `<!-- toc -->` and `<!-- tocstop -->`. Running the CLI a second
time produced identical file content, confirming CLI-level idempotency.

This verifies the external CLI in PowerShell. It does not yet verify
package resolution, process execution, command registration, or buffer
updates inside Neovim.

### Neovim validation

After integration, verify:

1.  `:MarkdownToc` is registered when the Markdown pack is enabled.
2.  A valid Markdown buffer receives the generated TOC.
3.  Unsaved buffer content is included.
4.  Repeated generation does not duplicate TOC entries.
5.  The buffer becomes modified when output changes, but the file is not
    saved automatically.
6.  Missing, duplicated, or incorrectly ordered markers produce clear
    warnings.
7.  Missing Node.js or `markdown-toc` produces an actionable error.
8.  The command works with the installed `@frat/markdown-toc` package on
    Windows + WezTerm.
9.  An edit made while generation is running is not overwritten by a
    stale result.
10. A wiped buffer or superseded request is handled safely.
11. A non-modifiable buffer is not changed.
12. Temporary files are removed after success, failure, or superseded
    requests.
13. The original buffer's `endofline` setting is preserved.
14. No automatic TOC generation or dependency installation occurs.

Do not mark the Neovim TOC workflow complete until these checks pass.

## 7. Markdown Rendering and Preview

Markdown preview is separate from the core editing workflow. Two
independent preview implementations are supported by the architecture,
with different installation profiles.

### Installation policy

  ---------------------------------------------------------------------------
  Plugin                            Installation profile Rendering
                                                         environment
  --------------------------------- -------------------- --------------------
  `delphinus/md-render.nvim`        Default baseline     Inside Neovim

  `sammaji/markdown-preview.nvim`   Optional, explicit   External browser
                                    opt-in               
  ---------------------------------------------------------------------------

The default baseline includes `md-render.nvim`. The optional browser
preview is installed only when the user explicitly selects it.

Both plugins must:

-   Use native `vim.pack`.
-   Have independent configuration modules.
-   Keep preview activation under user control.
-   Avoid automatic preview rendering during startup or buffer opening.
-   Avoid automatically opening a browser.
-   Document external dependencies and installation procedures.
-   Avoid silent downloads and implicit package installation.
-   Have independent tests and failure handling.
-   Remain independent of the Marksman, formatter, and linting
    workflows.

Installation, configuration loading, and preview activation are separate
operations:

1.  **Installation:** The plugin is available locally through the
    selected installation profile.
2.  **Configuration loading:** Its configuration prepares options and
    user commands without starting a preview.
3.  **Activation:** The user explicitly requests rendering through the
    plugin's documented command or mapping.

Installing a preview plugin does not authorize it to start a preview
server, open a browser, render a document, or download additional
software automatically.

### 7.1 Default baseline: `md-render.nvim`

Repository: https://github.com/delphinus/md-render.nvim

`md-render.nvim` provides in-editor Markdown rendering. It is the
selected default baseline preview because it keeps the rendered document
inside the Neovim workflow and documents support for CommonMark
paragraph behavior and CJK-aware rendering.

Its required capabilities include:

-   Markdown rendering inside Neovim.
-   Mermaid diagrams rendered as inline images.
-   PlantUML diagrams rendered as inline images using a local renderer
    or an explicitly configured server.
-   CommonMark soft-break handling.
-   Correct paragraph continuation inside list items and blockquotes.
-   CJK-aware paragraph joining without inserting unintended spaces
    between CJK characters.
-   CJK-aware line wrapping, including its documented kinsoku behavior
    and optional phrase segmentation.

The plugin documents image and media rendering through terminal graphics
capabilities. Its Windows + WezTerm compatibility has now been exercised
in the target environment and reported as passing. The baseline
admission decision is recorded below.

#### Compatibility environment

The evaluation environment is:

-   Windows.
-   Neovim 0.12.6.
-   WezTerm `20240203-110809-5046fc22`.

The target environment used for validation is Windows, Neovim 0.12.6,
and WezTerm `20240203-110809-5046fc22`.

The user has reported that `md-render.nvim` validation passed in this
environment. This target-environment result, rather than upstream
platform claims alone, is the basis for accepting it as the default
baseline. Preserve the exact plugin revision and detailed test output in
the plugin inventory or validation record when available.

#### Dependency and installation policy

Identify and document the actual dependencies required by the selected
feature set.

Potential dependencies include:

  -----------------------------------------------------------------------
  Dependency              Purpose                 Policy
  ----------------------- ----------------------- -----------------------
  Terminal graphics       Displays rendered       Windows + WezTerm
  support                 images inside Neovim    compatibility
                                                  validation reported
                                                  passed

  `curl`                  Retrieves remote media  External executable;
                          when enabled            installation must be
                                                  explicit

  Mermaid CLI (`mmdc`)    Renders Mermaid         Install and pin
                          diagrams                explicitly if used

  PlantUML renderer       Renders PlantUML        Prefer a local,
                          diagrams locally        explicitly managed
                                                  renderer

  Java and PlantUML JAR   Alternative local       Document exact
                          PlantUML rendering path requirements if
                                                  selected

  PlantUML server         Alternative remote      Configure explicitly;
                          rendering path          disclose source
                                                  transmission

  FFmpeg and `ffprobe`    Media conversion and    Optional; not required
                          video-related features  for basic Markdown
                                                  rendering

  ImageMagick             Image conversion        Optional; not required
                          fallback where          for basic Markdown
                          supported               rendering
  -----------------------------------------------------------------------

The exact required set depends on the features admitted into the
configuration. Do not treat every optional media dependency as mandatory
for basic Markdown preview.

Do not permit implicit `npx` or package-manager fallback to download
Mermaid CLI or other packages. If a required executable is missing,
report the missing dependency and explain how to install it explicitly.

For PlantUML, prefer local rendering where practical. If a remote server
is selected, require an explicit server configuration and document that
diagram source is transmitted to that server.

#### Compatibility validation record

**Result: Passed.** The user reports successful validation of
`md-render.nvim` on the target Windows + WezTerm environment. The plugin
is accepted as the default baseline.

The default plugin module installs `delphinus/md-render.nvim` through
native `vim.pack`. `budoux.lua` is not installed unconditionally: it is
an optional dependency for Japanese phrase segmentation and must remain
separately selected if that feature is needed.

The user-facing mappings live in `lua/config/keymaps.lua` and invoke the
plugin's documented `<Plug>` mappings:

``` lua
vim.keymap.set("n", "<leader>mp", "<Plug>(md-render-preview)", {
  desc = "Markdown preview",
})

vim.keymap.set("n", "<leader>mt", "<Plug>(md-render-preview-tab)", {
  desc = "Markdown preview in tab",
})

vim.keymap.set("n", "<leader>md", "<Plug>(md-render-demo)", {
  desc = "Markdown render demo",
})
```

These mappings preserve manual activation. The plugin is installed and
configured without automatically opening a preview during startup or
buffer entry.

Retain the following compatibility and dependency checks as regression
coverage:

Verify:

1.  The exact repository and plugin revision.
2.  The plugin loads through native `vim.pack`.
3.  The plugin works with the target Neovim version.
4.  Basic Markdown rendering works on Windows + WezTerm.
5.  Image rendering works in the actual terminal environment.
6.  Mermaid diagrams render as inline images.
7.  PlantUML diagrams render through the selected local renderer or
    explicitly configured server.
8.  CommonMark soft breaks join source lines into the same paragraph.
9.  List-item continuation lines remain part of the correct list item.
10. Blockquote continuation lines remain inside the blockquote.
11. CJK paragraph joining does not introduce unwanted spaces.
12. CJK line wrapping follows the documented behavior.
13. Missing optional executables produce actionable diagnostics.
14. Preview startup does not trigger unapproved downloads.
15. Closing and reopening a preview works reliably.
16. Preview failures do not damage the source buffer or ordinary editing
    workflow.

Record the exact plugin revision, Neovim version, Windows environment,
WezTerm version, terminal graphics behavior, dependency versions, and
test results.

#### Baseline admission decision

**Accepted**

`md-render.nvim` is admitted to the default baseline. Its Windows +
WezTerm validation was reported as passed. Keep optional dependencies
separate and continue to manage all external tools explicitly.

The optional browser preview remains independent. Its evaluation is not
a prerequisite for using or maintaining the accepted `md-render.nvim`
baseline.

### 7.2 Optional extension: `markdown-preview.nvim`

Repository: https://github.com/sammaji/markdown-preview.nvim

This is an optional browser-based preview workflow. It is not an inline
terminal renderer.

The maintained fork provides live browser preview, synchronized
scrolling, Markdown rendering, images, mathematical notation, diagrams,
and theme support. Its documentation describes Windows x64 support and a
native `vim.pack` installation path.

The plugin is installed only when the user explicitly selects the
optional extension. Its absence must not affect the default in-editor
preview or core Markdown editing.

#### Installation and dependency policy

The maintained fork provides a prebuilt server binary for Windows x64.
Its documentation describes downloading a matching binary when needed
and provides an explicit Windows installation script.

Do not add an automatic Neovim startup installer for this dependency.

Before admitting the optional extension:

-   Verify the exact repository and revision.
-   Verify the Windows x64 server binary.
-   Determine how the server binary will be installed and updated
    explicitly.
-   Verify that the plugin can be loaded through `vim.pack`.
-   Confirm that preview startup does not trigger an unapproved
    background installation.
-   Document browser and server requirements.
-   Keep its installation separate from the baseline `md-render.nvim`
    installation.

Installation documentation: https://mkdp.sammaji.com/installation

#### Isolated evaluation requirements

Evaluate the plugin independently in a temporary checkout and clean
Neovim session.

Verify:

1.  The plugin loads without errors.
2.  The preview opens in the selected browser.
3.  Ordinary Markdown text renders correctly.
4.  Tables, callouts, links, task lists, and fenced code blocks render
    correctly.
5.  Local images resolve correctly.
6.  Remote images work when network access is available.
7.  Mathematical notation and diagrams behave as documented.
8.  Preview updates follow edits to the source buffer.
9.  Synchronized scrolling behaves correctly.
10. Closing and reopening the preview works reliably.
11. Browser and server processes are cleaned up correctly.
12. The source Markdown remains intact and editable.
13. Preview failures do not damage the ordinary editing workflow.
14. Missing server binaries do not trigger unapproved downloads.

Record the exact plugin revision, server version, Neovim version,
Windows environment, browser, test results, and relevant errors.

#### Optional admission decision

Record one of the following:

-   **Accepted:** The optional browser preview works reliably in the
    target environment and its dependencies can be managed explicitly.
-   **Deferred:** Useful preview features work, but compatibility or
    stability needs further investigation.
-   **Rejected:** The plugin cannot meet the requirements without
    unacceptable complexity or instability.

A deferred or rejected optional extension does not block the default
in-editor preview or core Markdown language pack.

### 7.3 Shared rendering requirements and test fixtures

Use shared Markdown fixtures to compare the rendering behavior of both
plugins without requiring identical rendering engines or presentation.

#### Mermaid

Both preview workflows must be tested with a representative Mermaid
diagram.

Example:

``` mermaid
flowchart TD
    A[Open Markdown] --> B[Parse document]
    B --> C[Render preview]
    C --> D[View diagram]
```

Verify that the diagram renders as a visual diagram rather than
remaining an unprocessed code block.

For `md-render.nvim`, verify inline image rendering and the explicitly
installed Mermaid renderer. For the browser extension, verify its
documented Mermaid rendering behavior.

#### PlantUML

Both preview workflows must be tested with a representative PlantUML
diagram.

Example:

``` plantuml
@startuml
User -> Neovim: Open Markdown
Neovim -> Renderer: Render diagram
Renderer --> Neovim: Return image
Neovim --> User: Display preview
@enduml
```

Verify local and remote rendering behavior separately where supported.

For remote rendering, document the configured endpoint and disclose that
diagram source is sent to the server. Local rendering is preferred where
practical.

#### CommonMark paragraph behavior

Test soft line breaks using ordinary Markdown source lines:

``` markdown
This is a paragraph
that continues on another source line
without creating a new paragraph.

- First list item
  with a continuation line
  that belongs to the same item.

> This is a blockquote
> continued on another source line.
```

Verify that:

-   Soft-wrapped source lines join into the same paragraph.
-   Blank lines still separate paragraphs.
-   List-item continuation lines remain part of the same list item.
-   Blockquote continuation lines remain inside the blockquote.
-   Rendering does not insert unintended paragraph boundaries.

#### CJK paragraph and wrapping behavior

Include Japanese, Chinese, and mixed-language text in the shared
fixture.

Example:

``` markdown
これは日本語の文章です。
次の行も同じ段落に続きます。

这是一个中文段落。
下一行继续同一个段落。

Mixed text: 日本語とEnglishが同じ段落にあります。
```

Verify that paragraph joining does not insert unwanted spaces between
CJK characters and that line wrapping does not split text in ways that
violate the renderer's documented CJK behavior.

The dedicated CJK-aware behavior is a required capability for the
baseline `md-render.nvim` evaluation. Do not assume that the browser
extension implements the same specialized line-wrapping rules.

## 8. Intended Workflow

The intended Markdown workflow is:

1.  Edit Markdown in a normal Neovim buffer.
2.  Use Marksman for supported language intelligence and link
    navigation.
3.  Run `:Format` when source formatting is needed.
4.  Run `:MarkdownLint` to check rule compliance.
5.  Run `:MarkdownToc` when the document's table of contents needs to be
    generated or updated.
6.  Use `md-render.nvim` when in-editor visual inspection is needed.
7.  Use `markdown-preview.nvim` only when the optional browser extension
    is installed and browser-based rendering is wanted.
8.  Return to the source buffer for edits and repeat the relevant
    checks.

Neither preview starts automatically when Neovim opens or when a
Markdown buffer is entered.

Formatting and linting must remain independently usable. Failure to
render a preview must not prevent ordinary Markdown editing,
language-server support, formatting, or linting.

## 9. Dependencies

The dependency documentation must distinguish verified components,
required external executables, optional dependencies, and pending
candidates.

  -----------------------------------------------------------------------
  Dependency                Purpose                Policy
  ------------------------- ---------------------- ----------------------
  Marksman executable       Markdown language      Core configured
                            server                 component;
                                                   installation and
                                                   runtime behavior
                                                   require verification

  Prettier executable and   Markdown formatting    Core formatter;
  runtime                                          installation and
                                                   formatting behavior
                                                   require verification

  `markdownlint-cli2`       Markdown linting       Included in current
                                                   Stage 13
                                                   implementation

  `markdown` Tree-sitter    Markdown syntax        Declared primary
  parser                    parsing and            parser; verify
                            highlighting           availability

  `markdown_inline`         Inline Markdown syntax Declared parser
  Tree-sitter parser        parsing and            dependency; verify
                            highlighting           availability

  `markdown-toc`            Markdown               Explicit TOC command;
                            table-of-contents      CLI v1.3.0 verified in
                            generation             PowerShell; Neovim
                                                   integration pending
                                                   validation

  `markdown-deps.ps1`       Checks and installs    Windows-only helper;
                            Markdown CLI tools     execution and
                                                   validation pending

  Node.js and npm           Runtime and package    Required only for
                            manager for the two    installing or running
                            Markdown CLI tools     the managed CLI tools

  `md-render.nvim`          Default in-editor      Default baseline;
                            Markdown preview       Windows + WezTerm
                                                   validation passed;
                                                   accepted

  Terminal graphics support Displays rendered      Required for image
                            images inside Neovim   features; verify on
                                                   Windows + WezTerm

  Mermaid CLI (`mmdc`)      Renders Mermaid        Explicitly managed
                            diagrams               external dependency if
                                                   used

  PlantUML renderer         Renders PlantUML       Prefer an explicitly
                            diagrams locally       managed local renderer

  Java and PlantUML JAR     Alternative local      Document exact
                            PlantUML rendering     requirements if
                            path                   selected

  PlantUML server           Alternative remote     Explicit configuration
                            diagram rendering      required; disclose
                                                   source transmission

  `curl`                    Retrieves remote media External executable;
                            where enabled          install explicitly

  FFmpeg and `ffprobe`      Media conversion and   Optional; not required
                            video-related features for basic Markdown
                                                   rendering

  ImageMagick               Image conversion       Optional; not required
                            fallback where         for basic Markdown
                            supported              rendering

  `markdown-preview.nvim`   Optional browser-based Opt-in plugin;
                            live Markdown preview  isolated compatibility
                                                   evaluation required

  Browser                   Displays the optional  Required only when the
                            browser preview        browser extension is
                                                   selected

  Preview server binary     Serves rendered        Windows x64 binary;
                            Markdown to the        installation and
                            browser                update policy must be
                                                   verified
  -----------------------------------------------------------------------

Do not describe a tool as installed merely because its configuration or
dependency is documented. Update dependency records only after verifying
installation instructions and requirements.

Keep core Markdown requirements separate from optional preview
dependencies. Do not make video, animation, or diagram tooling mandatory
for basic Markdown authoring.

The existing Windows dependency setup script must not be assumed to
install Marksman, Prettier, `markdownlint-cli2`, or preview dependencies
unless its implementation is explicitly updated and validated through
the project's normal process.

Do not introduce automatic `npx`, Node.js package-manager, or
plugin-triggered downloads as an implicit dependency installation
mechanism.

### 9.1 Windows Markdown CLI dependency management

**Script:** `scripts/core/windows/markdown-deps.ps1`

The script manages only the two Node.js-based Markdown CLI tools used by
this specification:

  --------------------------------------------------------------------------------------
  Tool                  npm package            Executable            Responsibility
  --------------------- ---------------------- --------------------- -------------------
  `markdownlint-cli2`   `markdownlint-cli2`    `markdownlint-cli2`   Markdown linting

  `markdown-toc`        `@frat/markdown-toc`   `markdown-toc`        On-demand
                                                                     table-of-contents
                                                                     generation
  --------------------------------------------------------------------------------------

Node.js and npm are prerequisites for installation. They are not
installed by this script.

#### Default check mode

Running the script without parameters performs a check only:

``` powershell
pwsh -NoProfile -File .\scripts\core\windows\markdown-deps.ps1
```

Check mode must:

-   Detect each executable through the current process PATH.
-   Run the executable's `--version` command.
-   Report each tool as available, missing, or failed.
-   Avoid installing, upgrading, or modifying either package.
-   Return exit code `0` only when both tools are available and their
    version checks succeed.
-   Return a nonzero exit code when a tool is missing or its check
    fails.

#### Explicit installation mode

Installation is opt-in:

``` powershell
pwsh -NoProfile -File .\scripts\core\windows\markdown-deps.ps1 -InstallMissing
```

When `-InstallMissing` is supplied, the script must:

-   Confirm that npm is available before attempting installation.
-   Install only missing packages globally.
-   Use `markdownlint-cli2` for the linter and `@frat/markdown-toc` for
    the TOC generator.
-   Avoid upgrading packages that are already installed.
-   Verify each executable and its version after installation.
-   Resolve npm's global executable directory and make it available to
    the current script process when necessary.
-   Avoid persistent machine-wide or user-wide PATH changes.
-   Report installation and verification failures clearly.
-   Return a nonzero exit code if either required tool remains
    unavailable.

The script must not install Node.js, change Neovim configuration, modify
project Markdown files, or install preview plugins or renderer binaries.
It must not invoke `npx` as an implicit installation fallback.

#### Script validation status

The script design and invocation contract are specified, but its
execution on the target Windows environment has not yet been confirmed.
Do not mark this dependency-management workflow verified until the
following checks pass:

1.  Check mode succeeds when both tools are installed.
2.  Check mode reports a missing tool without installing it.
3.  Check mode returns a nonzero exit code when a tool is missing.
4.  `-InstallMissing` installs only missing packages.
5.  Existing packages are not upgraded.
6.  Post-install executable and version checks succeed.
7.  npm absence is reported clearly when installation is requested.
8.  A missing global npm executable directory is handled for the current
    process without persistent PATH mutation.
9.  Installation failures and post-install verification failures return
    nonzero exit codes.
10. The script does not install or modify unrelated dependencies.

The script is a Windows dependency-management convenience. It does not
replace the repository's general dependency documentation or authorize
Neovim to install external tools automatically.

## 10. Testing Strategy

Validation covers shared infrastructure, the Markdown pack, the default
preview, and the optional preview extension.

### Automated checks

-   Configuration modules load successfully.
-   The Markdown language pack is discovered and enabled correctly.
-   Markdown filetype and parser checks are repeatable.
-   Formatter metadata selects the intended formatter.
-   Missing formatter executables produce actionable diagnostics.
-   Invalid formatter preferences are rejected by the shared
    configuration validator.
-   LSP metadata and server configuration follow the established
    contract.
-   Lint commands and configuration are validated.
-   Valid and invalid lint fixtures produce the expected results.
-   `:MarkdownToc` command registration, package resolution,
    temporary-file execution, buffer updates, stale-result handling, and
    cleanup are validated.
-   `markdown-deps.ps1` check-only behavior, explicit installation,
    post-install verification, PATH handling, and exit codes are tested
    on Windows.
-   Preview plugin configurations remain independent.
-   Default and optional installation selection is deterministic.
-   Preview configuration loading does not start rendering.
-   Existing syntax and smoke tests pass.
-   No duplicate filetype ownership or formatter metadata is introduced.
-   Existing configuration behavior and formatting conventions are
    preserved.

Automated checks must follow the project's actual test interfaces. Do
not create parallel validation frameworks for Markdown when existing
shared checks can cover the same contract.

### Markdown fixtures

The core Markdown fixture should cover headings, lists, links, tables,
fenced code blocks, and inline formatting.

The lint fixture should include deliberate rule violations so the lint
workflow can demonstrate that it detects errors.

The shared preview fixture should include:

-   Ordinary paragraphs and soft line breaks.
-   Nested lists and continuation lines.
-   Blockquotes.
-   Tables and links.
-   Fenced code blocks.
-   Local and remote images.
-   Mermaid diagrams.
-   PlantUML diagrams.
-   Mathematical notation.
-   Japanese and Chinese paragraphs.
-   Mixed CJK and Latin text.

Keep preview-specific tests isolated from core language-pack checks.

### Interactive checks

-   Marksman starts, attaches, and provides the intended Markdown
    language features.
-   Prettier formats a representative document correctly through
    `:Format`.
-   `markdownlint-cli2` reports expected findings and failures.
-   `:MarkdownToc` generates and updates the current buffer without
    saving it automatically.
-   Markdown and inline Markdown syntax highlighting behave correctly.
-   `md-render.nvim` passes in-editor rendering, image, diagram,
    CommonMark, and CJK tests on Windows + WezTerm.
-   `markdown-preview.nvim` passes browser, image, scrolling, cleanup,
    and source-integrity tests if the optional extension is admitted.
-   Neither preview starts automatically during startup or buffer
    opening.
-   Neither preview silently downloads external dependencies.

### Current validation record

-   The Markdown language pack is implemented and enabled through
    centralized language configuration.
-   The TOC CLI dependency and command behavior are verified in
    PowerShell; Neovim-side integration remains pending.
-   Tree-sitter parser aliases and availability were verified for
    Markdown; both `markdown` and `markdown_inline` parsers were loaded
    and exercised.
-   Markdown syntax highlighting and fenced-code parsing were
    interactively checked.
-   `markdownlint-cli2` configuration and the custom JSON formatter were
    verified through both the command shim and direct Node.js
    entrypoint.
-   The Neovim `:MarkdownLint` command passed for a named Markdown
    buffer.
-   Project-root discovery was verified with Neovim's working directory
    outside the repository.
-   The Markdown lint integration's unsaved-buffer, diagnostic,
    stale-result, malformed-output, and missing-dependency paths were
    exercised in the earlier test set.
-   The unnamed-buffer case still falls back to Neovim's current working
    directory; a clearer root policy is a follow-up improvement.
-   `md-render.nvim` validation on Windows + WezTerm was reported as
    passed. The plugin is accepted as the default baseline.
-   `@frat/markdown-toc` v1.3.0 was installed globally and its CLI
    generation and repeated-run idempotency were verified in PowerShell.
    Neovim integration remains pending interactive validation.
-   The `markdown-deps.ps1` check/install script has been specified for
    `markdownlint-cli2` and `markdown-toc`; target-Windows execution and
    validation remain outstanding.
-   Preview mappings are defined in `lua/config/keymaps.lua`; preview
    activation remains manual.
-   `budoux.lua` is not part of the default installation because it is
    an optional Japanese line-breaking dependency.
-   Marksman runtime attachment and Prettier's interactive `:Format`
    workflow remain outstanding.
-   `markdown-preview.nvim` optional-extension compatibility remains
    unevaluated.
-   The document's last recorded `scripts/smoke.lua` run failed at
    `scripts/smoke.lua:789` with `config.options was loaded`. Rerun the
    current smoke suite to determine whether this historical failure
    remains present; do not report the overall suite as passing until
    verified.
-   Record the exact `md-render.nvim` revision and detailed validation
    output in `docs/plugin-inventory.md` when available.

A passing module load does not prove that external executables are
installed, that a language server attaches, that linting works, or that
a preview behaves correctly.

### Failure behavior

Tests must distinguish a missing optional dependency from a broken core
configuration.

-   A missing Marksman executable must be reported clearly and must not
    be represented as successful server startup.
-   A missing Prettier executable must produce a clear formatting
    warning or error.
-   A missing `markdownlint-cli2` executable must produce an actionable
    linting error.
-   A missing npm executable when installation is requested must be
    reported without attempting package installation.
-   A failed global package installation or failed post-install check
    must produce a nonzero script exit code.
-   Invalid lint configuration must be reported clearly.
-   Missing `md-render.nvim` rendering dependencies must be reported
    clearly without silently installing them.
-   A default preview compatibility failure must be visible and must not
    damage the core language pack.
-   A missing optional browser preview dependency must not affect the
    default preview.
-   Invalid configuration and duplicate metadata must fail visibly
    according to the shared architecture's validation rules.

## 11. Documentation Requirements

Update supporting documentation when the relevant implementation or
evaluation has been verified.

### `docs/dependencies.md`

Document:

-   Verified Marksman installation and executable checks.
-   Verified Prettier installation and runtime requirements.
-   Verified `markdownlint-cli2` installation and invocation.
-   Markdown parser requirements and verification.
-   `md-render.nvim` installation, terminal graphics requirements, and
    verified Windows + WezTerm compatibility.
-   Mermaid CLI and PlantUML renderer requirements where selected.
-   Optional media dependencies such as FFmpeg and ImageMagick.
-   `markdown-preview.nvim` browser and server requirements if the
    optional extension is admitted.
-   A clear distinction between required core tools, default preview
    dependencies, and optional browser-preview dependencies.

### `docs/plugin-inventory.md`

Record:

-   Each Markdown-related component's role.
-   Whether each plugin or integration is admitted, pending, deferred,
    or rejected.
-   The default baseline and optional extension installation profiles.
-   Relevant compatibility constraints.
-   Evidence supporting preview admission decisions.
-   The separation between external executables and Neovim plugins.

Do not list a candidate as an admitted plugin merely because it appears
in this specification.

### `docs/roadmap.md`

Keep Stage 13 marked **In Progress** while implementation and validation
continue.

Do not mark the Markdown scope complete while required core tests,
interactive verification, or dependency documentation remain unfinished.
Keep optional preview validation and admission decisions separate from
core completion.

### Decision documentation

Record material plugin-admission or compatibility decisions in the
appropriate decision record or plugin inventory entry. This
specification records the selected installation policy but does not
replace the required compatibility evidence.

## 12. Implementation Order

Continue from the current implementation. Do not recreate the language
pack or repeat completed work.

1.  Rerun the current smoke suite and investigate the previously
    recorded failure at `scripts/smoke.lua:789` if it still occurs.
2.  Verify Marksman executable availability and test actual LSP startup
    and attachment.
3.  Verify Prettier executable availability and test `:Format` on
    representative Markdown content.
4.  Review the Markdown pack metadata and keep only fields consumed by
    existing shared infrastructure.
5.  Complete and record any remaining lint fixture coverage; retain the
    verified `:MarkdownLint` workflow.
6.  Integrate `lua/langs/markdown/toc.lua` into the Markdown pack and
    validate `:MarkdownToc` in Neovim, including stale-result handling,
    cleanup, unsaved content, and no-save behavior.
7.  Validate `scripts/core/windows/markdown-deps.ps1` in check-only and
    explicit installation modes on Windows; record its actual behavior
    before treating it as a verified dependency workflow.
8.  Update `docs/dependencies.md` with verified core executable, parser,
    TOC CLI, dependency-script, and preview requirements.
9.  Record the exact `md-render.nvim` revision and detailed Windows +
    WezTerm validation evidence in `docs/plugin-inventory.md`.
10. Optionally improve unnamed-buffer root handling without changing the
    verified named-buffer workflow.
11. Evaluate `sammaji/markdown-preview.nvim` separately if and when the
    optional browser extension is selected.
12. Close the core Markdown scope only after its remaining required
    automated, interactive, and documentation criteria pass.

Do not combine unrelated earlier-stage closeout tasks with Markdown
implementation. Do not allow optional browser-preview evaluation to
block core Markdown work.

## 13. Acceptance Criteria

### Core Markdown language-pack scope

The core Markdown scope is complete when:

-   The Markdown pack follows the established language-pack
    architecture.
-   The pack is enabled through centralized language configuration.
-   Marksman is configured and its expected behavior is verified.
-   Prettier is registered through existing formatter metadata and works
    through `:Format`.
-   `markdownlint-cli2` is integrated into the documented Markdown
    workflow and its behavior is verified through `:MarkdownLint`.
-   `:MarkdownToc` is integrated into the Markdown pack and generates or
    updates the current buffer from unsaved content without automatic
    saving or dependency installation.
-   `markdown-deps.ps1` checks both Markdown CLI tools by default and
    installs only missing packages when `-InstallMissing` is supplied.
-   The script verifies installed executables, avoids persistent PATH
    changes, and returns meaningful exit codes.
-   The script's Windows behavior is tested and documented before it is
    marked verified.
-   Format-on-save remains disabled by default.
-   LSP formatting fallback remains disabled by default.
-   Markdown and inline Markdown Tree-sitter parsers are verified.
-   Shared registry and formatter validation checks pass.
-   Existing syntax and smoke checks pass.
-   Required dependencies and installation instructions are documented
    accurately.
-   The core workflow works without either preview plugin.
-   Interactive verification confirms the actual language-server,
    formatting, and linting workflows.

### Default preview scope

**Accepted and validated**

The default preview scope has passed the user's Windows + WezTerm
validation. The following criteria remain the durable acceptance
contract and regression checklist:

-   `md-render.nvim` is admitted to the default profile and installed
    through native `vim.pack`.
-   The target Windows + WezTerm validation has been reported as passed.
-   The exact plugin revision and detailed test evidence are recorded in
    the plugin inventory.
-   In-editor rendering works on the target Windows + WezTerm
    environment.
-   Required image rendering works in the actual terminal.
-   Mermaid diagrams render as inline images.
-   PlantUML diagrams render through the selected local renderer or
    explicitly configured server.
-   CommonMark soft breaks, list continuations, and blockquote
    paragraphs render correctly.
-   CJK paragraph joining does not introduce unintended spaces.
-   CJK line wrapping follows the required behavior.
-   Required and optional dependencies are identified accurately.
-   External dependencies can be installed and updated explicitly.
-   Preview activation remains user-controlled.
-   The baseline admission decision is **Accepted**; retain the
    supporting validation evidence.

### Optional browser-preview scope

The optional extension scope is complete when:

-   `markdown-preview.nvim` has been evaluated independently against a
    recorded plugin revision.
-   Its installation is opt-in.
-   Browser preview and required Markdown rendering behavior work in the
    target environment.
-   Local and remote image behavior has been tested.
-   Mermaid and PlantUML behavior has been tested.
-   Scrolling, cleanup, repeated operations, and source integrity have
    been tested.
-   Required and optional dependencies have been identified accurately.
-   No unapproved automatic download occurs.
-   An explicit optional-extension admission decision is recorded with
    supporting evidence.

Do not use completion of one component as evidence that the entire
Markdown scope is complete. A deferred or rejected optional
browser-preview extension does not invalidate a successfully completed
core language pack or default preview.

## References

-   Marksman: https://github.com/artempyanykh/marksman
-   Prettier: https://prettier.io/docs
-   markdownlint-cli2: https://github.com/DavidAnson/markdownlint-cli2
-   md-render.nvim: https://github.com/delphinus/md-render.nvim
-   markdown-preview.nvim:
    https://github.com/sammaji/markdown-preview.nvim
-   markdown-preview.nvim installation:
    https://mkdp.sammaji.com/installation

> **Approval is not installation.** Every component must earn its place
> through a defined responsibility, documented dependency, and
> reproducible validation.
