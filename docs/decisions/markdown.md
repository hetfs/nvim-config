# Markdown Support

## Purpose

Define the implementation, dependency, workflow, and validation requirements for Markdown authoring in `nvim-config`.

Markdown is part of the planned Stage 13 language-pack scope because project documentation is an important daily workflow. The design combines focused tools with distinct responsibilities rather than relying on one plugin to provide language intelligence, formatting, linting, syntax highlighting, and visual rendering.

> **Minimum installation. Compose the rest.**

## Status

- **Stage:** 13 — Language Packs
- **Document status:** Proposed implementation specification
- **Core implementation status:** Pending implementation and validation
- **Linting status:** Pending separate Stage 11 review and explicit admission
- **Rendering status:** Candidate; isolated compatibility evaluation required
- **Plugin admission:** No new plugin is admitted by this document

This document defines the intended implementation and evaluation process. It does not authorize installing plugins or external tools, modifying the active configuration, or beginning Stage 13 implementation ahead of the project’s outstanding earlier-stage requirements.

The implementation gate remains:

1. Complete the outstanding Stage 04 native-workflow and documentation requirements.
2. Complete the required interactive verification for Stage 10 completion and snippets.
3. Complete the remaining Stage 12 documentation, dependency, keymap, and closeout requirements.
4. Review the Stage 11 linting decision separately before selecting a Neovim lint integration.
5. Begin Stage 13 implementation only after the applicable prerequisites are resolved.

The Markdown renderer has an additional, independent compatibility gate. Its evaluation must not block the core Markdown language-pack implementation once Stage 13 is authorized.

## Design Principles

- Prefer Neovim's built-in capabilities where they adequately satisfy the requirement.
- Separate language-server configuration, formatting, linting, syntax highlighting, and visual rendering.
- Use Neovim's native `vim.pack` workflow for plugins that are explicitly admitted.
- Keep external executables separate from plugin installation.
- Follow the existing language-pack architecture and centralized user configuration.
- Preserve the manual formatting contract: no format-on-save and no LSP formatting fallback by default.
- Validate the actual Windows and WezTerm environment before admitting a renderer that depends on terminal graphics.
- Keep optional linting and rendering independent of the core Markdown language pack.
- Reuse existing shared LSP, formatter, and validation infrastructure rather than introducing Markdown-specific frameworks.
- Distinguish a proposed tool from an admitted dependency and a configured component from a verified workflow.
- Do not mark Markdown support complete until the relevant implementation, dependency documentation, automated checks, and required interactive validation are complete.

## Component Responsibilities and Status

| Component | Responsibility | Status |
|---|---|---|
| Tree-sitter | Markdown syntax parsing and highlighting | Existing integration; parser availability and behavior require verification |
| Marksman | Markdown language-server features, including link navigation, completion, references, and diagnostics | Proposed for core implementation |
| Prettier | Markdown source formatting | Proposed for core implementation |
| `markdownlint-cli2` | Markdown style and consistency linting | Candidate; separate Stage 11 review and admission required |
| `md-render.nvim` | Rich Markdown preview, including inline images | Candidate; isolated compatibility evaluation and admission required |

These components are complementary, not interchangeable.

Marksman provides language intelligence rather than visual rendering. Prettier formats source text rather than displaying images. `markdownlint-cli2` checks Markdown rules rather than replacing the formatter. Tree-sitter provides syntax parsing and highlighting, not a complete rendered preview.

The core Markdown language pack must remain usable without the optional linting and rendering components.

References:

- Marksman: https://github.com/artempyanykh/marksman
- Prettier: https://prettier.io/docs
- `md-render.nvim`: https://github.com/delphinus/md-render.nvim

## 1. Language-Pack Architecture

Markdown support must follow the existing language-pack architecture and its established interfaces.

### Core pack

The Markdown language pack belongs in:

`lua/langs/markdown.lua`

It should expose the established pack interface and declare the Markdown-specific language-server configuration and formatter metadata supported by the shared architecture.

The existing language-pack registry is responsible for discovering and initializing the pack. The pack must not independently install plugins or external executables, introduce a separate loader, or duplicate shared formatter and LSP infrastructure.

Before implementation, verify the actual interfaces in the current repository. The specification must not be used to assume that a helper or configuration field exists when it has not been implemented.

### Shared infrastructure

Reuse the existing shared infrastructure for:

- Registering and enabling language servers through Neovim's native LSP APIs.
- Collecting and validating formatter metadata.
- Resolving user-preferred and exclusive formatters where supported.
- Reporting missing external executables.
- Validating filetype ownership and detecting duplicate metadata.
- Reporting invalid configuration clearly.
- Preserving the existing startup and error-handling contract.

Do not introduce a separate Markdown-specific loader, formatter framework, or configuration path.

### User configuration

User-facing language configuration belongs in:

`lua/config/languages.lua`

Use the existing configuration fields to override formatter preferences or select exclusive formatters where those options are supported by the implementation.

Markdown defaults belong in the language pack. User-specific preferences belong in the centralized language configuration. Do not add a separate Markdown-only preference mechanism.

### Optional components

Markdown linting and rendering must be admitted independently. Neither should become a mandatory dependency of `lua/langs/markdown.lua` unless a separate, explicit architecture decision changes the core scope.

The absence or failure of an optional component must not prevent ordinary Markdown editing, language-server support, or source formatting.

## 2. Tree-sitter Integration

Verify that the existing Tree-sitter setup supports Markdown and inline Markdown syntax.

### Requirements

- Markdown files receive the expected Neovim filetype.
- The `markdown` and `markdown_inline` parsers are available and usable.
- Headings, fenced code blocks, lists, links, and inline formatting receive appropriate highlighting.
- Missing parsers are reported accurately rather than assumed to be installed.
- Parser availability and relevant behavior are checked through repeatable validation where practical.
- Parser installation requirements remain separate from plugin installation and language-pack configuration.

Tree-sitter remains responsible for syntax parsing and highlighting. It does not replace Marksman, Prettier, linting, or rendering.

Do not install another Markdown syntax-highlighting plugin to duplicate the existing Tree-sitter responsibility without a demonstrated requirement and a separate admission decision.

### Validation

Verify parser availability in the actual supported environment. Where feasible, include automated checks for expected filetype detection and parser availability, while retaining interactive checks for visible highlighting behavior.

A passing configuration smoke test alone does not prove that every required parser is installed or that highlighting is correct.

## 3. Markdown Language Server

**Proposed implementation target:** Marksman.

Marksman provides Markdown language intelligence, including supported link completion, navigation, references, and diagnostics. It is distributed as a platform-specific executable and supports Windows.

Its inclusion in this specification is a proposed implementation direction, not evidence that the executable is installed or that a new plugin has been admitted.

### Implementation requirements

- Register Marksman through the existing language-pack and native LSP architecture.
- Use the shared language-server helper and established server configuration conventions, if provided by the current implementation.
- Configure and activate the server using Neovim's native LSP APIs.
- Keep the Marksman executable independently managed from plugin installation.
- Verify the server identifier and configuration against the installed `nvim-lspconfig` definitions and supported Neovim version.
- Validate behavior on individual Markdown files and within a project workspace.
- Test internal links, heading navigation, references, and diagnostics where applicable.
- Document verified installation and executable requirements in `docs/dependencies.md`.
- Report a missing executable through the established LSP status and diagnostic conventions.
- Treat an invalid or missing server definition as a visible configuration error rather than silently ignoring it.

Marksman's project-wide features may depend on workspace-root detection, repository context, or a `.marksman.toml` marker. Verify the behavior in the actual configuration instead of assuming that every Markdown file has the same workspace context.

Do not introduce a second project-root detection mechanism solely for Markdown. Reuse existing root-detection behavior where compatible, and document any verified Marksman-specific requirements.

### Validation

Verify at least the following:

1. Marksman is recognized by the configured LSP architecture.
2. The server starts and attaches when its executable and configuration are available.
3. A missing executable is reported clearly and is not misrepresented as successful startup.
4. Link navigation and other supported features work in a representative Markdown project.
5. Opening an individual Markdown file and opening a file inside a project produce understandable, expected behavior.
6. Workspace-root behavior is tested rather than inferred from the presence of a server configuration.
7. Existing LSP behavior and language packs remain unaffected.

Automated checks should validate the configuration contract without requiring a live server process. Interactive verification must establish actual server startup and attachment.

## 4. Markdown Formatting

**Proposed formatter:** Prettier.

Formatting must use the existing manual formatting interface through `:Format` and Conform.

### Implementation requirements

- Register Prettier for the Markdown filetypes supported by the configuration.
- Declare the default formatter through the established language-pack formatter metadata.
- Preserve the existing formatter-resolution contract.
- Validate user-preferred and exclusive formatter overrides through the shared configuration system.
- Report unavailable formatter executables clearly.
- Keep format-on-save disabled by default.
- Keep LSP formatting fallback disabled by default.
- Keep formatting independent from linting and preview rendering.
- Keep formatter installation and runtime requirements separate from Neovim plugin installation.

Use the centralized language configuration for supported Markdown formatter overrides. Do not introduce a separate Markdown-only formatter preference mechanism.

Before implementation, confirm the existing formatter metadata fields, supported override behavior, and missing-executable handling from the current code. Do not invent new fields to accommodate this specification.

### Validation

Format representative Markdown documents containing:

- Headings and paragraphs.
- Ordered and unordered lists.
- Tables.
- Inline links and reference links.
- Fenced code blocks.
- Inline code and emphasis.
- Long paragraphs and nested content.

Confirm that `:Format` invokes the intended formatter, produces expected output, and reports unavailable executables clearly.

Also verify that:

- Formatting remains an explicit user action.
- Format-on-save has not been enabled inadvertently.
- LSP formatting is not silently used as a fallback.
- Formatter selection respects the shared configuration contract.
- Other filetypes retain their existing formatter behavior.

Prettier documentation: https://prettier.io/docs

## 5. Markdown Linting

**Candidate:** `markdownlint-cli2`.

Linting is separate from formatting. The linter identifies rule violations; it must not be treated as the formatter or renderer.

This component remains pending a separate Stage 11 review and explicit admission. Its presence in this document does not mean it is installed, approved, or integrated into Neovim.

### Admission requirements

Before integration:

- Confirm the executable, runtime requirements, supported invocation, and platform compatibility.
- Decide whether linting will be a manual command, a Neovim-integrated workflow, or both.
- Define how lint results, execution failures, and missing dependencies are reported.
- Establish the intended rule policy and configuration ownership.
- Add repeatable checks for valid and deliberately invalid Markdown fixtures.
- Document verified installation and dependency requirements.
- Decide whether integration requires a dedicated Neovim plugin or whether the executable can be used directly.
- Confirm that the proposed workflow does not duplicate existing functionality without a clear benefit.

Do not assume that installing the linter automatically integrates it into Neovim. Do not assume that formatting resolves every lint warning.

### Configuration boundary

Review the linting rule policy and its configuration ownership only after the linter has been formally admitted. Until then, do not treat any proposed lint configuration as validated or change it as part of the renderer evaluation.

Linting must remain independent of the core Markdown language pack. The absence of the linter must not prevent Markdown editing, language-server support, or formatting.

The linting integration decision must follow the separate Stage 11 review; it must not be made implicitly through Stage 13 implementation.

## 6. Markdown Rendering and Images

**Candidate:** `md-render.nvim`.

The objective is to inspect rendered Markdown, including inline images, without leaving the Neovim workflow.

The plugin advertises rich text formatting, tables, callouts, code blocks, local and remote images, and diagram integrations. These features must be tested rather than assumed to work in the target environment.

Project: https://github.com/delphinus/md-render.nvim

### Compatibility gate

The initial evaluation environment is:

- Windows.
- Neovim 0.12.6.
- WezTerm `20240203-110809-5046fc22`.

The plugin documents support for Neovim 0.12 or later and requires a terminal that supports the Kitty graphics protocol for inline images and video. Its README lists WezTerm among tested terminals, but the cited verification for WezTerm refers to macOS/Linux. This does not establish compatibility with the target Windows environment.

**Do not admit the renderer to the main configuration until the isolated evaluation passes.**

Verify the candidate's current requirements and implementation against the exact version being evaluated. Do not treat documentation for another operating system, a successful text-only preview, or terminal image support in isolation as proof that the full workflow is compatible.

### Isolated evaluation requirements

Evaluate the plugin in a temporary checkout and a clean Neovim session. Do not modify the repository's active `init.lua`, plugin inventory, or installed plugin set during the evaluation.

Verify:

1. The plugin loads without errors.
2. Ordinary Markdown text renders correctly.
3. Tables, callouts, links, and fenced code blocks render correctly.
4. A local PNG image appears inline in WezTerm.
5. Remote images work when network access and the required download support are available.
6. Scrolling, resizing, closing, and reopening the preview do not leave stale image fragments or corrupt terminal output.
7. The source Markdown remains intact and editable.
8. Closing the preview and exiting Neovim do not leave the terminal in an unexpected state.
9. Repeated preview operations remain stable.
10. Required external executables and feature-specific optional dependencies are identified accurately.
11. Failures in rendering do not damage the ordinary editing workflow.

Record the exact plugin commit, Neovim version, Windows environment, WezTerm version, test results, and relevant errors.

### Dependency boundaries

Do not install every optional renderer dependency in advance.

Potential dependencies include:

- `curl` for remote image or video downloads, depending on the tested plugin implementation.
- FFmpeg or ImageMagick for particular image conversions or animated content.
- Mermaid CLI or a documented fallback for Mermaid diagrams.
- Tree-sitter parsers for syntax highlighting inside rendered code blocks.

Confirm which dependencies are genuinely required by the tested version. Document only verified requirements and clearly distinguish required dependencies from feature-specific optional ones.

Evaluate basic Markdown preview and local PNG rendering before testing optional video, animation, or diagram features.

The fact that `wezterm imgcat` can display an image is not sufficient proof that the plugin's own graphics protocol, rendering lifecycle, and cleanup behavior work correctly.

### Admission decision

After testing, record one of the following decisions:

- **Accepted:** Required preview and image behavior works reliably in the target environment.
- **Deferred:** Some useful rendering features work, but required image behavior or stability needs further investigation.
- **Rejected:** The renderer cannot meet the requirements without unacceptable complexity or instability.

A successful text-only preview is not sufficient to accept a plugin whose required purpose includes inline images.

Record the decision and its evidence in the relevant plugin and dependency documentation. Until acceptance is supported by test evidence, the renderer remains optional and unadmitted.

The rendering evaluation is independent of the core language-pack implementation. A deferred or rejected renderer must not block Marksman or Prettier integration after the Stage 13 implementation gate has been satisfied.

## 7. Intended Workflow

After implementation and validation, the intended workflow is:

1. Edit Markdown in a normal Neovim buffer.
2. Use Marksman for supported language intelligence and link navigation.
3. Run `:Format` when source formatting is needed.
4. Run the Markdown lint workflow independently, if the linter is admitted.
5. Open the rich preview when visual inspection is needed, if the renderer passes the compatibility gate.
6. Return to the source buffer for edits and repeat the relevant checks.

Formatting and linting must remain usable independently of the renderer. Failure to render images must not prevent ordinary Markdown editing, language-server support, formatting, or linting.

The core Markdown workflow must not require the renderer or an unadmitted linter to be installed.

## 8. Dependencies

The final dependency documentation must distinguish between existing and verified components, required external executables, optional dependencies, and pending candidates.

| Dependency | Purpose | Policy |
|---|---|---|
| Marksman executable | Markdown language server | Proposed core dependency after implementation is approved |
| Prettier executable and runtime | Markdown formatting | Proposed core dependency after implementation is approved |
| `markdownlint-cli2` and its runtime | Markdown linting | Pending Stage 11 review and admission |
| `markdown` Tree-sitter parser | Markdown syntax parsing and highlighting | Verify availability in the existing parser setup |
| `markdown_inline` Tree-sitter parser | Inline Markdown syntax parsing and highlighting | Verify availability in the existing parser setup |
| `md-render.nvim` | Rich preview and image rendering | Optional plugin candidate; pending compatibility approval |
| `curl` | Remote media retrieval, if required by the accepted renderer workflow | Verify actual usage before documenting as required |
| FFmpeg / ImageMagick | Selected image and video conversions | Optional and feature-dependent |
| Mermaid CLI | Mermaid diagram rendering | Optional and feature-dependent |

Do not describe a tool as installed merely because its configuration or dependency is documented. Update dependency records only after verifying installation instructions and requirements.

Keep core Markdown requirements separate from optional rendering dependencies. Do not make video, animation, or diagram tooling mandatory for basic Markdown authoring.

The existing Windows dependency setup script must not be assumed to install Marksman, Prettier, the linting executable, or renderer dependencies unless its implementation is explicitly updated and validated through the project's normal process.

## 9. Testing Strategy

Validation must cover shared infrastructure, the Markdown pack, and any separately admitted optional components.

### Automated checks

- Configuration modules load successfully.
- The Markdown language pack is discovered and registered correctly.
- Markdown filetype and parser checks are repeatable.
- The formatter registry selects the intended formatter.
- Missing formatter executables produce actionable diagnostics.
- Invalid formatter preference entries are rejected by the shared configuration validator.
- LSP metadata and server configuration follow the established contract.
- Lint fixtures pass or fail as expected if linting is admitted.
- Existing syntax and smoke tests remain passing.
- No duplicate filetype ownership or formatter metadata is introduced.
- Existing configuration behavior and formatting conventions are preserved.

Automated checks must follow the project's actual test interfaces. Do not create parallel validation frameworks for Markdown when existing shared checks can cover the same contract.

### Markdown fixtures

Use representative fixtures for different validation purposes.

The core Markdown fixture should cover headings, lists, links, tables, fenced code blocks, and inline formatting.

A separate lint fixture should contain deliberate rule violations so the lint workflow can demonstrate that it detects errors, but only after linting has been admitted.

Renderer evaluation should use a dedicated fixture containing ordinary text, tables, callouts, code blocks, local images, and remote images where available. Keep renderer-specific tests isolated from the core language-pack checks.

### Interactive checks

- Marksman starts, attaches, and provides the intended Markdown language features.
- Prettier formats a representative document correctly through `:Format`.
- The lint workflow reports actionable errors if the linter is admitted.
- Markdown and inline Markdown syntax highlighting behave correctly.
- The renderer passes the text, image, scrolling, cleanup, and source-integrity tests if it is accepted.

### Failure behavior

Tests must distinguish a missing optional dependency from a broken core configuration.

- A missing Marksman executable must be reported through the established LSP status or diagnostic path.
- A missing Prettier executable must produce a clear formatting warning or error.
- An unadmitted or unavailable linter must not break the core Markdown workflow.
- A renderer compatibility failure must not affect the core language pack.
- Invalid configuration and duplicate metadata must fail visibly according to the shared architecture's validation rules.

Do not interpret a successful module load as proof that external executables are installed, that a language server attaches, or that a renderer behaves correctly in the target terminal.

## 10. Documentation Requirements

Update supporting documentation only when the relevant implementation or evaluation has been verified.

### `docs/dependencies.md`

Document:

- Verified Marksman installation and executable checks.
- Verified Prettier installation and runtime requirements.
- Markdown parser requirements and verification.
- Linter requirements only after admission.
- Renderer dependencies based on the tested plugin version and accepted feature set.
- A clear distinction between required core tools and optional dependencies.

### `docs/plugin-inventory.md`

Record:

- Each Markdown-related component's role.
- Whether each plugin or integration is admitted, pending, deferred, or rejected.
- Relevant compatibility constraints.
- The evidence supporting a renderer admission decision.
- The separation between external executables and Neovim plugins.

Do not list a candidate as an admitted plugin merely because it appears in this specification.

### `docs/roadmap.md`

Keep Stage 13 marked **Planned** until the applicable implementation gate is satisfied and implementation begins through the project's normal stage process.

Update Stage 13 status only when the relevant implementation and validation criteria have been met. Do not mark Markdown support complete while required core tests or documentation remain unfinished.

### Decision documentation

Record material plugin-admission or compatibility decisions in the appropriate decision record or plugin inventory entry. This specification alone does not constitute an admission decision.

## 11. Implementation Order

Once the Stage 13 implementation gate has been satisfied, follow this sequence for the Markdown scope:

1. Verify the existing Markdown filetype and Tree-sitter parser behavior.
2. Implement and validate the Marksman language-pack integration.
3. Add Prettier to the existing formatter-resolution workflow.
4. Validate Markdown formatting through `:Format`.
5. Review and implement the Markdown lint workflow separately, only after the Stage 11 decision and explicit admission.
6. Evaluate `md-render.nvim` in isolation on Windows and WezTerm.
7. Record the renderer decision based on reproducible test results.
8. Update dependency and plugin documentation with verified information.
9. Close the Markdown scope only after the required core validation is complete and each optional component has an explicit decision.

The renderer evaluation is an independent compatibility gate. It must not block implementation of the core Markdown language pack once the project authorizes Stage 13 work.

Do not combine unrelated earlier-stage closeout tasks with the Markdown implementation, and do not treat this specification as permission to bypass them.

## 12. Acceptance Criteria

### Core Markdown language-pack scope

The core Markdown scope is complete when:

- The Markdown pack follows the established language-pack architecture.
- Marksman is configured and its expected behavior is verified.
- Prettier is registered through the existing formatter metadata and works through `:Format`.
- Format-on-save remains disabled by default.
- LSP formatting fallback remains disabled by default.
- Markdown and inline Markdown Tree-sitter parsers are verified.
- Shared registry and formatter validation checks pass.
- Existing syntax and smoke checks remain passing.
- Required dependencies and installation instructions are documented accurately.
- The core workflow works without the optional linter or renderer.
- Interactive verification confirms the actual language-server and formatting workflows.

### Linting scope

The linting scope is complete only after:

- The Stage 11 linting decision has been reviewed.
- The linter has been explicitly admitted.
- Its dependency and configuration policy has been documented.
- Valid and invalid fixtures demonstrate the expected behavior.
- The chosen workflow reports useful diagnostics and failures.
- The core Markdown workflow remains functional when the linter is unavailable.

### Rendering scope

The rendering scope is complete only after:

- The isolated compatibility evaluation has been performed against a recorded plugin version.
- Required text and inline-image behavior works in the target Windows and WezTerm environment.
- Scrolling, resizing, cleanup, repeated operations, and source integrity have been tested.
- Required and optional dependencies have been identified accurately.
- An explicit admission decision is recorded with supporting evidence.

Do not use completion of one component as evidence that the entire Markdown scope is complete. A deferred or rejected optional component does not invalidate a successfully completed core language pack.

## References

- Marksman: https://github.com/artempyanykh/marksman
- Prettier: https://prettier.io/docs
- `md-render.nvim`: https://github.com/delphinus/md-render.nvim

> **Approval is not installation.** Every component must earn its place through a defined responsibility, documented dependency, and reproducible validation.

