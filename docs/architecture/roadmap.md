# Roadmap

## Current Status

- **Stages 01–03:** Complete.
- **Stage 04 — Native Workflows:** In progress. The native commenting workflow remains unresolved. The stage must not be closed until its outstanding requirements are implemented and validated.
- **Stages 05–09:** Complete. Stage 09's native LSP and lazydev implementation, including its defined validation, is closed out.
- **Stage 10 — Completion and Snippets:** Implementation is in place. Interactive verification remains in progress. Completion, snippet expansion, and related behavior must be verified before formal closeout.
- **Stage 11 — Format and Lint:** Complete for the defined manual formatting implementation and automated validation. Python's Ruff native LSP lint integration was also implemented and validated as part of the Python language pack.
- **Stage 12 — Git, Root, and Sessions:** In progress. Gitsigns, `DrKJeff16/project.nvim`, and `mini.sessions` are implemented. Interactive checks for Git workflows, project navigation, and session save/restore have passed. Stage 12 smoke-test checks also pass on Neovim 0.12.6. Related documentation, dependency and keymap alignment, and remaining stage-closeout requirements are still outstanding.
- **Stage 13 — Language Packs:** Complete. All 11 core language groups and all 5 additional language and tooling integrations, including MDX, are implemented and validated.
- **Stage 14 — Development Workflows:** Implementation in progress. CodeCompanion configuration work has been completed, but its full acceptance status remains to be established.
- **Stage 15 — Debugging:** Deferred. Debugging implementation has not been admitted into the active work.
- **Stage 16:** Reserved pending scope definition.
- **Stages 17–20:** Implemented; behavioral or runtime acceptance remains outstanding.
- **Stages 21–22:** Complete. Acceptance tests passed.
- **Stages 23–26:** Implemented; behavioral or visual acceptance remains outstanding.
- **Stages 27–28:** Complete. Acceptance tests passed.
- **Stages 29–31:** Planned.

Stage completion is based on defined implementation, validation, and closeout requirements. Later-stage work must not be used to imply that an earlier stage's outstanding requirements have been resolved.

In particular:

- Stage 12 does not reopen Stage 09.
- Stage 13's completed language packs do not close Stage 10.
- Stage 13 does not change the completion status of Stage 11.
- Additional language-specific integrations do not change the agreed core language baseline.
- Configuration files or successful startup alone do not establish stage completion.
- Plugin admission does not establish installation or behavioral acceptance.
- Keymap registration does not establish that the associated workflow works correctly.
- Passing tests in a later stage does not automatically close an earlier stage.

> Update this status whenever a stage formally changes. Keep implementation progress, validation results, and formal closeout status distinct.

---

## Stage 13 — Language Packs

**Status:** Complete.

**Objective:** Extend the configuration for selected programming, markup, and tooling environments while keeping language support modular, dependencies explicit, and tool installation separate from Neovim startup.

### Language support overview

Stage 13 covers 11 core language groups, implemented in the agreed order, and 5 additional integrations.

- **Core baseline:** 11 language groups.
- **Additional integrations:** 5.
- **Total:** 16 completed language and tooling integrations.

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
| MDX | Additional | Complete |

MDX is an additional integration alongside Markdown. Its completion does not change the core language baseline or the agreed implementation order.

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
- Maintain Markdown and MDX support as distinct but related integrations.

### Completion criteria

- All 11 core language groups are implemented.
- All 5 additional integrations are implemented.
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
- MDX remains classified as an additional integration, not a twelfth core language group.

Stage 13 is complete. All 11 core language groups and all 5 additional integrations, including MDX, are implemented and validated.

---

## Stage 14 — Development Workflows

**Status:** Implementation in progress; acceptance pending.

**Objective:** Extend the configuration with additional development workflows while preserving modular plugin ownership, explicit dependencies, and native Neovim integration.

### Selected integration

| Plugin | Intended role | Status |
|---|---|---|
| codecompanion.nvim | AI-assisted chat and inline editing | Configuration work completed; acceptance pending |

CodeCompanion provides AI-assisted development workflows through a local OpenAI-compatible server.

The integration must remain optional and must not replace native editing, LSP, completion, or formatting capabilities.

### Scope

- Configure CodeCompanion through its dedicated plugin module.
- Keep provider and adapter configuration explicit.
- Document the local OpenAI-compatible server requirements.
- Keep credentials and sensitive configuration out of the repository.
- Define project-owned keymaps.
- Preserve existing language and editing workflows.
- Validate chat, inline editing, and provider connectivity.

### Implementation boundaries

- Do not introduce another AI plugin without an explicit architectural decision.
- Do not make an external AI service mandatory for ordinary Neovim startup.
- Keep local server configuration separate from plugin configuration where appropriate.
- Avoid conflicting with existing `<leader>c*` language workflows.
- Keep external services and executables separate from Neovim plugin installation.
- Do not treat successful plugin loading as proof that the provider works.

### Completion criteria

- CodeCompanion loads through the normal configuration startup path.
- The provider and adapter configuration is valid.
- The local OpenAI-compatible server can be reached.
- Chat workflows operate successfully.
- Inline editing operates successfully.
- Project-owned mappings work without collisions.
- Existing LSP, completion, formatting, and editing workflows remain intact.
- External requirements and configuration instructions are documented.
- Applicable syntax, smoke, and interactive tests pass.

Stage 14 must remain open until its defined acceptance criteria are satisfied.

---

## Stage 15 — Debugging

**Status:** Deferred.

**Objective:** Introduce a modular debugging environment with explicit debugger dependencies and language-specific configuration.

### Candidate components

| Plugin or dependency | Intended role | Admission status |
|---|---|---|
| nvim-dap | Debug Adapter Protocol client | Deferred |
| nvim-dap-ui | Debugging interface | Deferred |
| nvim-nio | Asynchronous dependency where required | Not admitted |
| Debug adapters | Connect to language runtimes and debuggers | External tools; selection pending |

The user has deferred DAP implementation. No debugging dependencies should be installed or configured until the stage's scope and supported workflows have been defined.

### Implementation boundaries

- Keep debugger configuration separate from language-server configuration.
- Make debugger dependencies explicit.
- Avoid installing unrelated debugging tools.
- Keep language-specific debugger setup modular.
- Reuse the existing language-pack architecture where appropriate.
- Validate launch, breakpoint, stepping, and inspection workflows where applicable.

### Completion criteria

To be defined when the stage is explicitly reopened.

---

## Stage 16 — Reserved

**Status:** Scope not defined.

This stage remains reserved. No plugin or implementation requirement is admitted under this stage until its purpose, scope, dependencies, and completion criteria are established.

Do not assign work to Stage 16 merely to fill a numbering gap.

---

## Stage 17 — nvim-spider

**Status:** Implemented; behavioral acceptance pending.

**Objective:** Improve word and subword navigation while preserving native editing semantics.

| Plugin | Intended role |
|---|---|
| nvim-spider | Word and subword motion with improved punctuation handling |

### Scope

- Configure word and subword movement.
- Support normal, visual, and operator-pending modes.
- Preserve the project's movement and editing conventions.
- Configure the agreed `cw` remapping.

### Completion criteria

- Word and subword movement behave as expected.
- Punctuation handling is correct.
- Normal, visual, and operator-pending behavior is validated.
- The `cw` remapping behaves as intended.
- Existing movement mappings are not unintentionally replaced.
- Syntax and startup checks pass.

The implementation and mapping checks do not establish behavioral acceptance. Stage 17 remains open until the movement tests pass.

---

## Stage 18 — yanky.nvim

**Status:** Implemented; behavioral acceptance pending.

**Objective:** Add yank history and enhanced put operations without replacing native register and clipboard behavior.

| Plugin | Intended role |
|---|---|
| yanky.nvim | Yank history, history navigation, and enhanced put operations |

### Scope

- Configure yank history.
- Provide previous and next history navigation.
- Integrate history search with Snacks Picker.
- Preserve native registers and clipboard behavior.
- Keep mappings within the existing keymap architecture.

### Implementation boundaries

- Preserve the existing visual-mode paste mapping that prevents overwriting the clipboard.
- Do not replace native register behavior unnecessarily.
- Keep Yanky put mappings in normal mode unless a separate visual-mode decision is approved.
- Preserve the existing `unnamedplus` clipboard configuration.
- Avoid conflicts with existing search-and-replace mappings.
- Keep the existing `<leader>r` namespace.

### Completion criteria

- Yank history works.
- Normal-mode put operations work.
- Previous and next history navigation work.
- Snacks Picker integration works.
- History persistence works.
- Numbered, unnamed, and clipboard registers behave correctly.
- Black-hole register behavior is preserved.
- The existing visual-mode paste mapping remains functional.
- History commands and clearing behavior work.
- Existing editing workflows remain intact.

Stage 18 remains open until interactive and native-register regression tests pass.

---

## Stage 19 — git-conflict.nvim

**Status:** Implemented; behavioral acceptance pending.

**Objective:** Provide merge-conflict highlighting, navigation, and resolution without replacing existing Git integrations.

| Plugin | Intended role |
|---|---|
| git-conflict.nvim | Merge-conflict highlighting, navigation, and resolution |

### Scope

- Highlight merge-conflict regions.
- Navigate between conflict regions.
- Resolve conflicts using the available resolution commands.
- Integrate conflict lists with the quickfix workflow.
- Preserve Gitsigns and Diffview responsibilities.

### Keymap ownership

- `<leader>gc*` is reserved for conflict workflows.
- `]x` and `[x` provide conflict navigation.
- Conflict quickfix and refresh operations use project-owned mappings.
- Existing `<leader>g*` Git mappings must remain intact.

### Completion criteria

- Plugin installation and health checks pass.
- Conflict highlighting works.
- Navigation between conflict regions works.
- Ours, theirs, both, and none resolution paths work.
- Conflict refresh works.
- Quickfix integration works.
- Gitsigns and Diffview workflows remain functional.

Stage 19 remains open until all resolution paths have been tested.

---

## Stage 20 — octo.nvim

**Status:** Implemented; runtime acceptance pending.

**Objective:** Integrate GitHub issue, pull request, and review workflows into Neovim.

| Plugin or dependency | Intended role |
|---|---|
| octo.nvim | GitHub issues, pull requests, and review workflows |
| GitHub CLI (`gh`) | Authenticate and communicate with GitHub |
| plenary.nvim | Required Lua utility dependency |

### Scope

- Integrate Octo with the existing plugin architecture.
- Use the configured Snacks picker integration.
- Keep GitHub authentication in the GitHub CLI.
- Provide project-owned mappings for GitHub workflows.
- Document external dependencies.

### Implementation boundaries

- Octo does not replace Git, Gitsigns, or Diffview.
- GitHub CLI remains an external executable.
- Verify `gh` availability from the Neovim process environment.
- Do not expose authentication tokens or credentials in configuration files or logs.
- Avoid duplicate installations of `plenary.nvim`.

### Completion criteria

- `gh` is executable from Neovim.
- Octo health checks pass.
- Issue listing works.
- Pull request listing works.
- An issue or pull request can be opened.
- The configured picker integration works.
- Authentication failures provide useful feedback.
- Existing Git workflows remain intact.

Stage 20 remains open until runtime validation inside Neovim passes.

---

## Stage 21 — nvim-ts-autotag

**Status:** Complete.

**Objective:** Automatically close and rename supported markup tags.

| Plugin | Intended role |
|---|---|
| nvim-ts-autotag | Automatic tag closing and renaming |

### Scope

- Enable automatic closing.
- Enable supported tag renaming.
- Reuse the existing Tree-sitter integration.
- Keep close-on-slash behavior disabled.

### Completion criteria

- Plugin loads through the normal configuration.
- Supported HTML and JSX/TSX tag closing works.
- Tag renaming works.
- Existing Tree-sitter workflows remain intact.
- Applicable tests pass.

**Validation:** The user confirmed that Stage 21 tests passed.

---

## Stage 22 — trouble.nvim

**Status:** Complete.

**Objective:** Provide structured views for diagnostics, symbols, locations, and TODO annotations.

| Plugin | Intended role |
|---|---|
| trouble.nvim | Structured diagnostics and navigation |

### Scope

- Workspace diagnostics.
- Current-buffer diagnostics.
- Document symbols.
- LSP locations.
- Location lists.
- Quickfix lists.
- TODO annotations.

### Completion criteria

- Plugin loads through the normal configuration.
- Project-owned mappings are registered.
- Diagnostics and symbol views work.
- LSP navigation works.
- Location and quickfix lists work.
- TODO integration works.
- Existing native diagnostic workflows remain intact.

**Validation:** The user confirmed that Stage 22 tests passed.

---

## Stage 23 — harpoon

**Status:** Implemented; behavioral acceptance pending.

**Objective:** Provide quick navigation among explicitly selected project files.

| Plugin or dependency | Intended role |
|---|---|
| harpoon | Project-file marking and navigation |
| plenary.nvim | Shared dependency |

### Scope

- Add the current file to the Harpoon list.
- Open the Harpoon menu.
- Select marked files.
- Persist list state.
- Preserve project.nvim working-directory behavior.

### Implementation boundaries

The implementation must remain compatible with the existing project.nvim configuration:

- `manual_mode = true`
- `autochdir = false`
- `scope_chdir = "global"`

Do not introduce a second automatic project-root or working-directory manager.

`plenary.nvim` must be installed once and activated where required.

### Completion criteria

- The current file can be added.
- The menu opens and displays the expected list.
- Marked files can be selected.
- Persistence works.
- Project separation behaves as expected for the configured workflow.
- Project.nvim working-directory behavior remains unchanged.
- Existing navigation mappings remain intact.

Keymap registration has been checked. Stage 23 remains open until behavioral tests pass.

---

## Stage 24 — lualine.nvim

**Status:** Implemented; visual acceptance pending.

**Objective:** Provide a configurable statusline with relevant editing and development information.

| Plugin | Intended role |
|---|---|
| lualine.nvim | Statusline presentation |

### Scope

- Display the current editing mode.
- Display Git branch and diff information.
- Display diagnostic counts.
- Display filename and file status.
- Display encoding, file format, and filetype.
- Display cursor progress and location.

### Implementation boundaries

- Lualine owns the statusline.
- Keep the configuration text-oriented.
- Do not require Nerd Font icons.
- Preserve native window and buffer behavior.
- Avoid duplicating Bufferline or Noice responsibilities.

### Completion criteria

- Mode display works.
- Git branch and diff information work.
- Diagnostic counts are correct.
- Active and inactive split-window behavior is correct.
- Colorscheme integration works.
- Bufferline and Noice coexist without presentation conflicts.

Installation and configuration inspection have been completed. Stage 24 remains open until visual acceptance tests pass.

---

## Stage 25 — bufferline.nvim

**Status:** Implemented; behavioral acceptance pending.

**Objective:** Provide buffer navigation and tabline presentation.

| Plugin | Intended role |
|---|---|
| bufferline.nvim | Buffer tabline and navigation |

### Scope

- Display open buffers.
- Navigate between buffers.
- Select buffers by ordinal.
- Pick buffers interactively.
- Pick and close buffers.
- Display modified-buffer and diagnostic indicators.

### Implementation boundaries

- Bufferline owns the buffer tabline.
- Do not treat it as a replacement for native windows or project sessions.
- Preserve existing buffer and window management.
- Avoid conflicting with Lualine.

### Completion criteria

- Multiple buffers display correctly.
- Next and previous navigation work.
- Buffer selection by ordinal works.
- Buffer picking works.
- Close-picking works.
- Modified-buffer indicators work.
- LSP diagnostic indicators work.
- Lualine coexistence works.
- Closing buffers does not cause unexpected window or project behavior.

Keymap registration has been verified. Stage 25 remains open until behavioral tests pass.

---

## Stage 26 — zen-mode.nvim

**Status:** Implemented; behavioral acceptance pending.

**Objective:** Provide a temporary focused editing layout.

| Plugin | Intended role |
|---|---|
| zen-mode.nvim | Focused editing layout |

### Scope

- Provide a centered editing window.
- Temporarily adjust selected display options.
- Provide toggle and explicit close mappings.
- Restore editor state after leaving the focused layout.

### Implementation boundaries

- Zen Mode must not become a second window-management system.
- Do not duplicate terminal management.
- Preserve project navigation and existing editor workflows.
- Keep optional integrations disabled unless explicitly required.

### Completion criteria

- Zen Mode can be entered.
- Toggle and explicit close mappings work.
- Window width and layout are correct.
- Editor options are restored.
- Interaction with Lualine and Bufferline is correct.
- Diagnostics, terminal workflows, and project navigation remain usable.

Stage 26 remains open until behavioral tests pass.

---

## Stage 27 — noice.nvim

**Status:** Complete.

**Objective:** Enhance command-line, message, and LSP progress presentation while retaining native completion and notification workflows.

| Plugin or dependency | Intended role |
|---|---|
| noice.nvim | Enhanced command-line and message presentation |
| nui.nvim | UI component dependency |
| Native Neovim UI | Completion, notifications, input, and selection |

### Accepted architecture

The accepted configuration is **Noice full integration with native completion and native notifications**.

Noice owns:

- Enhanced command-line presentation.
- Search command-line presentation.
- Message and error presentation.
- Message history.
- Selected command output presentation.
- LSP progress and message presentation.

Native Neovim retains:

- Completion popups.
- `vim.notify()`.
- `vim.ui.input()`.
- `vim.ui.select()`.
- Native diagnostics.
- Native hover and signature help.
- Native Markdown conversion.

### Implementation boundaries

- Do not install `nvim-notify`.
- Do not introduce Telescope.
- Keep Lualine, Bufferline, Trouble, Snacks, and fzf-lua responsibilities separate.
- Reuse the existing Tree-sitter integration.
- Preserve the project's supported Neovim version requirements.

### Completion criteria

- Enhanced command-line presentation works.
- Search presentation works.
- Messages and errors are presented correctly.
- Message history is accessible.
- LSP progress presentation works.
- Native completion remains active.
- Native notifications remain active.
- Existing UI plugins coexist without conflicting responsibilities.

**Validation:** The user confirmed that Stage 27 tests passed.

---

## Stage 28 — vim-illuminate

**Status:** Complete.

**Objective:** Highlight symbol references under the cursor using the available language and syntax providers.

| Plugin | Intended role |
|---|---|
| vim-illuminate | Symbol-reference highlighting |

### Scope

- Use LSP, Tree-sitter, and regex providers.
- Configure a controlled highlighting delay.
- Disable plugin-default keymaps.
- Use project-owned mappings.
- Avoid unnecessary highlighting in large files.

### Implementation boundaries

The native LSP configuration was audited before adopting the plugin. The inspected repository configuration did not contain a competing native document-highlight workflow.

The accepted configuration uses:

- LSP, Tree-sitter, and regex providers.
- A 150 ms delay.
- Project-owned keymaps.
- A large-file cutoff.

The project-owned mappings are:

| Mapping | Purpose |
|---|---|
| `<leader>ui` | Toggle symbol highlighting |
| `<leader>un` | Next symbol reference |
| `<leader>up` | Previous symbol reference |

### Completion criteria

- Symbol references are highlighted.
- LSP-backed highlighting works.
- Tree-sitter and regex fallback behavior works.
- Next and previous reference navigation work.
- Toggle behavior works.
- Large-file behavior is respected.
- Existing LSP, Tree-sitter, and diagnostic workflows remain intact.
- No conflicting native document-highlight workflow is introduced.

**Validation:** The user confirmed that Stage 28 tests passed.

---

## Stage 29 — Final Integration and Regression Testing

**Status:** Planned.

**Objective:** Consolidate the accepted plugin integrations and verify their behavior together before performance optimization or release preparation.

### Scope

- Complete all outstanding acceptance tests from Stages 17–20 and 23–26.
- Verify shared dependencies and plugin load order.
- Review global and buffer-local keymap collisions.
- Verify Git, navigation, editing, and UI integrations together.
- Run syntax, formatting, smoke, and regression checks.
- Verify the supported Neovim versions.
- Align architecture, plugin, dependency, and keymap documentation.
- Remove unused or duplicate plugin declarations.
- Review optional integrations and their failure behavior.

### Completion criteria

- All outstanding plugin acceptance tests pass.
- Shared dependencies are declared once and activated correctly.
- Plugin loading is deterministic.
- No unresolved runtime or dependency errors remain.
- Existing native workflows remain intact.
- UI plugins work together without conflicting ownership.
- Keymaps match the documented implementation.
- Syntax, formatting, smoke, and regression checks pass.
- Documentation reflects the actual repository.
- Known limitations are documented.

Stage 29 does not automatically admit additional plugins.

---

## Stage 30 — Performance and Lazy Loading

**Status:** Planned.

**Objective:** Evaluate startup and runtime behavior and introduce lazy loading only when measurements justify it.

Lazy loading must be evidence-driven and must preserve deterministic plugin behavior.

### Scope

- Establish a validated eager-loading baseline.
- Measure startup performance.
- Identify plugins with meaningful startup or runtime costs.
- Evaluate lazy-loading opportunities.
- Measure performance after any changes.
- Validate compatibility with supported Neovim versions.

### Implementation boundaries

- Do not introduce lazy loading before establishing a validated baseline.
- Do not add `lazy.nvim`.
- Preserve explicit plugin ownership and deterministic loading behavior.
- Verify plugin commands, events, dependencies, and user workflows after each change.
- Avoid introducing lazy-loading complexity without measurable benefit.
- Do not trade reliable startup behavior for insignificant performance gains.

### Completion criteria

- Baseline measurements are recorded.
- Any optimization has measurable justification.
- Startup and runtime behavior remain correct.
- Plugin commands and events remain available when expected.
- Dependencies load in the correct order.
- Interactive workflows pass after optimization.
- Performance results are documented.

---

## Stage 31 — Release Preparation

**Status:** Planned.

**Objective:** Complete documentation, dependency review, regression testing, compatibility checks, and release preparation.

### Scope

- Review the complete plugin and dependency inventory.
- Align documentation with the actual implementation.
- Validate supported operating systems and environments.
- Run the complete syntax, formatting, smoke, and workflow validation suites.
- Verify installation and bootstrap procedures.
- Review configuration consistency.
- Remove obsolete or duplicated material.
- Document known limitations and outstanding issues.
- Prepare release notes and versioning information.

### Implementation boundaries

- Do not introduce new plugins merely to complete release preparation.
- New dependencies must follow the normal admission process.
- Preserve the project's native-first architecture.
- Keep external-tool installation separate from plugin installation.
- Verify that documented workflows match the supported configuration.

### Completion criteria

- Documentation is consistent with the repository.
- External dependency requirements and supported versions are documented.
- Platform installation instructions are validated.
- The full validation suite passes.
- Installation and bootstrap procedures work.
- No unresolved release-blocking issues remain.
- Known limitations are documented.
- Release notes and version information are prepared.

---

## Roadmap Maintenance Rules

- Update stage status only when its defined implementation and validation requirements are satisfied.
- Keep implementation completion distinct from formal stage closeout when documentation, dependency alignment, keymap alignment, or other closeout requirements remain.
- Do not infer completion from configuration files, plugin installation, or successful startup alone.
- Keep stage ownership clear. Work in one stage must not silently change another stage's completion status.
- Record acceptance evidence separately from admission and implementation.
- Preserve deferred decisions until the relevant stage is explicitly reopened.
- Do not assign work to reserved stages without defining their scope.
- Keep this roadmap aligned with `docs/architecture.md`, `docs/dependencies.md`, and the Plugin Inventory.
