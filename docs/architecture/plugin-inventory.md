# Plugin Inventory

## Purpose

This document records plugin selections, implementation stages, architectural decisions, validation status, and admission boundaries for `nvim-config`.

The project follows a native-first approach: Neovim's built-in capabilities take priority, and external plugins are added only when they provide a justified benefit.

> **Approval is not installation.**

A plugin listed in this inventory is not automatically approved for installation. Its admission status records an architectural decision, not proof that it is installed, configured, or validated.

The inventory must reflect the actual repository and the current roadmap. It is not an aspirational list of plugins copied from other Neovim distributions.

## Plugin Admission Policy

Before a plugin is admitted, evaluate:

- **Purpose:** What concrete capability does it provide?
- **Native alternative:** Can Neovim already provide the required behavior?
- **Overlap:** Does it duplicate an existing plugin or workflow?
- **Dependencies:** Does it require external executables, libraries, parsers, or adapters?
- **Maintenance:** Is the project maintained and appropriate for this configuration?
- **Stage fit:** Does it belong to the active roadmap stage?
- **Validation:** How will its behavior be tested?
- **Removal cost:** Can it be removed without destabilizing unrelated configuration?

A plugin should be installed only after its role and stage have been explicitly accepted.

## Inventory Status Definitions

| Status | Meaning |
|---|---|
| Implemented | Configuration is present in the repository; runtime behavior must still be validated separately |
| Planned | Assigned to a future or active roadmap stage but not confirmed as implemented |
| Accepted | Explicitly approved for the stated purpose and stage; implementation and validation may still be outstanding |
| Deferred | Deliberately postponed pending a later stage or a documented decision |
| Candidate | Under consideration; not approved for installation |
| Rejected | Evaluated and not selected for the current architecture |

Interactive validation is recorded separately from implementation status.

A stage is complete only when its defined implementation and acceptance criteria have been satisfied. An installed plugin, registered keymap, passing syntax check, or successful smoke test does not independently establish full acceptance.

## Core Policy

### Native Neovim capabilities

Prefer built-in functionality for:

- Options, mappings, and autocommands.
- Window and buffer management where the native workflow is sufficient.
- Native commenting mappings.
- Built-in LSP configuration and activation APIs.
- Plugin management through `vim.pack`.
- Native Lua configuration and runtime facilities.

Native functionality should not be duplicated by a plugin without a documented reason.

### Plugin management

The project uses Neovim's built-in `vim.pack` plugin manager.

- Do not introduce `lazy.nvim` as the plugin manager.
- Keep plugin setup explicit.
- Avoid duplicate installations of shared repositories.
- Keep plugin loading eager through Stage 15.
- Evaluate lazy loading in Stage 30 only when measurements and compatibility testing justify it.

### External tools

External executables are managed separately from Neovim plugins.

Examples include language servers, formatters, linters, debuggers, compiler toolchains, Git utilities, and GitHub CLI.

Their installation requirements should be documented in `docs/dependencies.md` and relevant platform setup instructions.

The project does not adopt Mason as its default external-tool installation mechanism.

### Shared plugin repositories

Some plugins provide multiple independent modules through a shared repository.

For example, `mini.nvim` should be installed once. Individual Mini modules must be configured independently and enabled only when their respective roadmap requirements are admitted.

Do not add duplicate repository installations to obtain additional modules.

### Keymap ownership

Keymaps must have clear ownership and must not silently replace existing workflows.

- Keep shared keymap definitions in `lua/config/keymaps.lua`.
- Use buffer-local mappings where the feature depends on an attached buffer or language server.
- Preserve established leader-key namespaces.
- Check for collisions before introducing plugin mappings.
- Verify mappings with `:verbose nmap` or `:verbose xmap`.
- Test the actual behavior separately from mapping registration.

### UI ownership

UI plugins must have distinct responsibilities.

- Snacks owns its selected picker and explorer workflows.
- fzf-lua remains an independent fuzzy-finding integration.
- Lualine owns the statusline.
- Bufferline owns the buffer tabline.
- Trouble owns structured diagnostics and location lists.
- Noice owns enhanced command-line and message presentation.
- Native Neovim retains completion popups, notifications, and native UI input and selection workflows.
- Zen Mode provides a focused editing layout.
- vim-illuminate provides symbol-reference highlighting.

Do not add another UI plugin that duplicates an established responsibility without documenting the requirement.

---

## Stage-Based Inventory

The following inventory records established selections, implementation status, and roadmap direction. Verify actual installation and configuration against the repository before changing an item's implementation status.

### Stage 04 — Native Workflows

**Status:** In progress.

Stage 04 prioritizes native Neovim workflows before introducing plugins for equivalent functionality.

| Component | Intended role | Policy |
|---|---|---|
| Native commenting mappings | Comment and uncomment supported lines or selections | Preferred approach; workflow remains unresolved |
| Commenting plugins | Provide additional commenting behavior | Not admitted by default |

The native commenting workflow remains unresolved. Do not introduce a commenting plugin merely to close the stage. First establish the required behavior, evaluate Neovim's native capabilities, and validate the selected implementation.

### Stage 05 — Plugin Management and Colorscheme

| Plugin or tool | Intended role | Policy |
|---|---|---|
| Catppuccin | Colorscheme | Selected for the base UI |
| `vim.pack` | Native plugin management | Required; built into supported Neovim versions |

Catppuccin is configured through the plugin configuration layer. Plugin management remains native and does not depend on `lazy.nvim`.

### Stage 06 — Mapping Discovery and Icons

| Plugin | Intended role | Policy |
|---|---|---|
| which-key.nvim | Discover mappings and leader-key groups | Selected |
| mini.icons | Icon support for integrations | Selected |
| mini.nvim | Shared repository for Mini modules | Install once; configure modules independently |

`mini.nvim` is a shared repository. Individual Mini modules should be configured independently without adding duplicate repository installations.

### Stage 07 — Navigation and Editing

| Plugin | Intended role | Policy |
|---|---|---|
| folke/snacks.nvim | Navigation, picker facilities, and selected UI utilities | Selected; shared setup path |
| fzf-lua | Fuzzy finding and navigation | Selected; independent from Snacks Picker |
| flash.nvim | Fast motion and search navigation | Selected |
| mini.ai | Text objects | Selected Mini module |
| mini.move | Move selected text and lines | Selected Mini module |
| mini.surround | Surround editing | Selected Mini module |
| mini.hipatterns | Highlight configured text patterns | Candidate; confirm admission and stage assignment |

**Independence requirement:** Snacks Picker and fzf-lua must retain separate configuration and mapping decisions. Neither should silently replace the other.

**Shared setup requirement:** Snacks should have one shared setup path. Feature-specific configuration may be separated without duplicating the core setup.

The inventory must distinguish an admitted Mini module from one that is merely available through the shared repository.

### Stage 08 — Treesitter

| Plugin or dependency | Intended role | Policy |
|---|---|---|
| nvim-treesitter | Tree-sitter-based syntax parsing and highlighting | Selected |
| Compiler toolchain | Build parsers where required | External dependency; document per platform |
| Tree-sitter parsers | Language-specific syntax parsing | Configure deliberately; validate availability and compatibility |

The plugin and its parsers are separate concerns. Installing the plugin alone does not prove that every parser is installed, compiled, or working.

Parser coverage must follow the supported language baseline and the actual repository configuration. Missing parsers must be reported clearly rather than treated as successfully installed.

### Stage 09 — LSP and Lua Development

**Status:** Complete.

| Component | Decision | Responsibility |
|---|---|---|
| Neovim native LSP | Selected | Configure and activate language servers |
| `nvim-lspconfig` | Accepted and implemented | Supply maintained server definitions |
| `lazydev.nvim` | Selected and implemented | Improve LuaLS awareness of Neovim and Lua libraries |
| LuaLS (`lua-language-server`) | External dependency | Provide Lua diagnostics and language features |
| Python language tooling | Implemented in Stage 13 | Provide Python language support in its designated stage |
| Mason | Not selected | External tools remain externally managed |

Neovim's native `vim.lsp.config()` and `vim.lsp.enable()` APIs remain the configuration and activation interface. `nvim-lspconfig` supplies maintained server definitions; the project does not use its legacy `require("lspconfig")` interface.

The Lua language pack declares Lua-specific settings without unnecessarily duplicating upstream server defaults. LuaLS must be installed separately and available on `PATH`. `lazydev.nvim` enhances Lua development support but does not install or manage the server executable.

Python language-server support belongs to Stage 13. Its implementation does not change Stage 09's completion status or reopen its LSP foundation.

Stage 09 does not include completion, snippets, formatting, linting, Mason, or debugging.

**Completion boundary:** Stage 09's defined native LSP and lazydev implementation and validation requirements are closed out. Later language-specific work reuses this foundation rather than replacing it.

### Stage 10 — Completion and Snippets

**Status:** Implementation in place; interactive verification remains in progress.

| Plugin | Intended role | Policy |
|---|---|---|
| blink.cmp | Completion | Implemented; interactive verification remains outstanding |
| friendly-snippets | Reusable snippets | Implemented; interactive verification remains outstanding |
| mini.pairs | Automatic paired-character behavior | Verify implementation and interactive behavior against the current configuration |

These components belong to Stage 10. Their configuration and smoke-test coverage do not, by themselves, establish that completion, snippet expansion, or paired-character behavior works correctly in interactive use.

Keep completion sources, snippet integration, mappings, and plugin setup within Stage 10. Language packs may declare language-specific completion requirements, but must not independently replace the shared completion architecture.

### Stage 11 — Format and Lint

**Status:** Complete for the defined manual formatting implementation and automated validation.

| Plugin or component | Intended role | Policy |
|---|---|---|
| conform.nvim | Formatting integration | Implemented |
| Ruff native LSP integration | Python lint diagnostics | Implemented and validated in the Python language pack |
| Language-specific linters | Provide diagnostics where explicitly supported | Configure through the relevant language pack |
| External formatters and linters | Perform formatting and linting | External dependencies; document separately |

Conform owns the approved formatting integration. Formatting remains manual by default through the established formatting workflow.

The project does not enable format-on-save by default and does not use LSP formatting fallback without a separate architectural decision.

Ruff's native LSP lint integration is part of the Python language pack. It does not establish a requirement for a separate generic linting plugin or imply that every language uses the same linting workflow.

The installation and version management of formatters and linters remain separate from Neovim plugin management.

### Stage 12 — Git, Root, and Sessions

**Status:** In progress.

| Plugin or tool | Intended role | Policy |
|---|---|---|
| gitsigns.nvim | Git change indicators and hunk workflows | Implemented; interactive workflows verified |
| project.nvim (`DrKJeff16/project.nvim`) | Project-root detection, working-directory behavior, and project history | Accepted and implemented; core project navigation verified |
| mini.sessions (from shared `mini.nvim`) | Explicit session save, restore, and delete workflows | Implemented; session save and restore verified |
| lazygit | Optional terminal Git interface | Optional external executable; not a Neovim plugin |
| diffview.nvim | Git diff and file-history presentation | Selected and integrated; runtime validation recorded separately |
| git-conflict.nvim | Merge-conflict navigation and resolution | Accepted for Stage 19; behavioral validation pending |

#### Implementation and validation notes

- **Gitsigns:** Git change indicators and hunk workflows are configured. The central keymap module registers buffer-local mappings for staging a hunk, resetting a hunk, previewing a hunk, blaming a line, and diffing the current buffer. Interactive checks have confirmed the mappings and tested preview, blame, and diff behavior.
- **project.nvim:** Its configuration enables Git-based project detection, disables automatic directory changes, and uses global scope when an explicit directory change is requested. Project-root detection, the `:Project` command, project switching, and `get_project_root()` have been tested.
- **mini.sessions:** The implementation reuses the existing shared `mini.nvim` repository rather than installing a duplicate repository. Automatic session reads and writes are disabled. Explicit save, restore, and delete mappings are defined in the central keymap module. Interactive session save and restore have been tested.
- **diffview.nvim:** Git diff and file-history workflows have been configured with project-owned mappings. Git is the supported workflow. Missing optional integrations such as Mercurial or `nvim-web-devicons` must not be treated as blockers for the Git-only configuration.
- **git-conflict.nvim:** The plugin has been selected for merge-conflict navigation and resolution. Its installation and runtime behavior must be validated against the conflict fixture and acceptance tests.
- **Smoke tests:** Stage 12 registration checks pass on Neovim 0.12.6 using the normal configuration startup path. The broader smoke test also passes. These checks complement, but do not replace, interactive validation.
- **Optional executable:** Any lazygit workflow must check whether `lazygit` is available and provide clear feedback if it is missing.
- **External dependencies:** Requirements such as Git and any relevant project-navigation tools should be recorded in `docs/dependencies.md`. A plugin does not install its external dependencies.

#### Remaining closeout work

Stage 12 is not complete merely because its main modules and workflows have been implemented. Before closing the stage:

- Align the inventory, roadmap, dependency documentation, and keymap documentation with the implementation.
- Run the applicable syntax, formatting, smoke, and diff checks.
- Investigate and document the observed headless-exit warning from `project.nvim` history writing before deciding whether it requires a configuration change or can be safely treated as a non-blocking condition.
- Confirm that optional-tool behavior and documented mappings match the actual repository.

The implementation should remain eager-loaded under the project's current loading policy. Do not introduce a separate root module unless a demonstrated requirement justifies it.

### Stage 13 — Language Packs

**Status:** Complete.

Stage 13 extends the configuration with selected language-specific support after the foundational LSP, completion, and formatting stages.

The completed baseline contains 11 core language groups and 5 additional integrations.

#### Core language baseline

The 11 core language groups, in their agreed implementation order, are:

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

HTML and CSS are core language groups. They must not be moved into an optional web pack.

#### Additional integrations

| Language or integration | Classification | Status |
|---|---|---|
| C | Additional | Complete |
| C++ | Additional | Complete |
| Docker | Additional | Complete |
| SQL | Additional | Complete |
| MDX | Additional | Complete |

The five additional integrations extend the language environment without changing the 11-language core baseline or its implementation order.

#### Markdown and MDX support

Markdown and MDX are distinct integrations with related tooling requirements. Their configuration must preserve clear ownership boundaries.

| Plugin or tool | Intended role | Policy |
|---|---|---|
| md-render.nvim | Default terminal-native Markdown rendering | Selected baseline; implemented and validated |
| render-markdown.nvim | Alternative in-buffer Markdown rendering | Optional; not the default renderer |
| markdown-preview.nvim | Browser-based Markdown preview | Optional; independent extension |
| Marksman | Markdown language server | External executable |
| Tree-sitter Markdown parsers | Markdown syntax parsing | Required for configured parser workflows |
| Prettier | Formatting for supported Markdown and MDX workflows | External executable |
| markdownlint-cli2 | Markdown linting | External executable |
| `@frat/markdown-toc` | Table-of-contents generation | External tool |
| Mermaid tooling | Diagram generation and preview workflows | Separate tooling and workflow requirements |

The renderer choices have distinct responsibilities:

- **md-render.nvim:** The default rendering solution for the existing terminal-native workflow.
- **render-markdown.nvim:** An optional alternative for rendering inside the editing buffer. It must not be treated as the default renderer.
- **markdown-preview.nvim:** An optional browser-preview extension. It is independent of terminal-native and in-buffer rendering.

Do not treat these plugins as interchangeable or configure multiple renderers as competing defaults.

`markdown-preview.nvim` is not part of the baseline merely because it appears in this inventory. Its adoption requires a separate decision, configuration, keymap review, dependency review, and validation. Do not reuse mappings already owned by `md-render.nvim` without an explicit mapping decision.

MDX remains an additional integration, not a twelfth core language group. Its parser, language-server, formatting, linting, and other tooling requirements must be documented independently where they differ from Markdown.

#### Language-pack responsibilities

- Keep language-specific configuration modular.
- Reuse the native LSP registry and activation architecture established in Stage 09.
- Use Conform for approved formatting workflows.
- Document external language servers, formatters, linters, parsers, schemas, and other tools.
- Keep external executable installation and updates separate from plugin installation.
- Validate language-specific workflows independently.
- Keep additional integrations separate from the core language baseline.

#### Completion boundary

Stage 13 is complete. All 11 core language groups and all 5 additional integrations are implemented and validated.

Stage 13 does not reopen Stage 09, close Stage 10, or change the completion status of Stage 11.

### Stage 14 — Development Workflows

**Status:** Planned; selected integrations require final scope and acceptance criteria.

| Plugin | Intended role | Policy |
|---|---|---|
| codecompanion.nvim | AI-assisted chat and inline editing through a local OpenAI-compatible server | Selected; configuration work completed; acceptance status not established |

CodeCompanion is intended to provide an optional AI-assisted development workflow. It must remain independent of the core editing, LSP, completion, and formatting architecture.

Its provider configuration, server requirements, keymaps, and runtime behavior must be documented and validated before the stage is marked complete.

No additional plugin is automatically admitted by this stage. Each proposed workflow must be evaluated against existing native capabilities and plugins before installation.

### Stage 15 — Debugging

**Status:** Deferred.

| Plugin or dependency | Intended role | Policy |
|---|---|---|
| nvim-dap | Debug Adapter Protocol client | Deferred |
| nvim-dap-ui | Debugging interface | Deferred |
| nvim-nio | Asynchronous dependency where required | Dependency to document if adopted |
| Debug adapters | Connect to language runtimes and debuggers | External tools; configure selectively |

Debug adapters are not interchangeable with Neovim plugins. Their installation, compatibility, and language-specific requirements must be documented separately.

The user has deferred DAP implementation. Do not install or configure debugging dependencies until the stage's scope and supported workflows have been defined.

### Stage 16 — Performance and Lazy Loading

**Status:** Planned.

No additional plugin is automatically admitted by this stage.

Evaluate startup and runtime behavior first. Lazy loading may be introduced only where measurements justify it and compatibility with the supported Neovim version has been verified.

Requirements:

- Establish a validated eager-loading baseline before optimization.
- Measure startup performance before making changes.
- Introduce lazy loading only where measurements justify it.
- Preserve explicit plugin ownership and deterministic loading behavior.
- Verify plugin commands, events, dependencies, and user workflows after each change.
- Avoid introducing lazy-loading complexity without measurable benefit.

### Stage 17 — nvim-spider

**Status:** Accepted; behavioral acceptance pending.

| Plugin | Intended role | Policy |
|---|---|---|
| nvim-spider | Word and subword motion with improved punctuation handling | Accepted; preserve native operator-pending and text-editing semantics |

The plugin provides enhanced word movement for normal, operator-pending, and visual modes.

The implementation must preserve the existing editing workflow and verify the `cw` remapping behavior.

**Acceptance tests:**

- Verify word and subword movement.
- Verify punctuation handling.
- Verify normal, visual, and operator-pending behavior.
- Verify the `cw` remapping.
- Check that existing movement mappings are not unintentionally replaced.

Do not mark the stage complete until behavioral tests pass.

### Stage 18 — yanky.nvim

**Status:** Accepted; behavioral acceptance pending.

| Plugin | Intended role | Policy |
|---|---|---|
| yanky.nvim | Yank history and enhanced put operations | Accepted; retain native register and clipboard behavior |

Yanky provides a persistent yank history and navigation between previous entries.

The implementation uses the existing shared keymap architecture and integrates with Snacks Picker for history search.

**Architectural boundaries:**

- Keep the existing visual-mode paste mapping that prevents overwriting the clipboard.
- Do not replace native register behavior unnecessarily.
- Keep Yanky put mappings in normal mode unless a separate visual-mode decision is approved.
- Preserve the existing `unnamedplus` clipboard configuration.
- Use the existing `<leader>r` namespace without conflicting with search-and-replace workflows.

**Acceptance tests:**

- Verify yank history and navigation.
- Verify normal-mode put operations.
- Verify Snacks Picker integration.
- Verify history persistence.
- Verify numbered, unnamed, and clipboard registers.
- Verify black-hole register behavior.
- Verify the existing visual-mode paste mapping.
- Verify history commands and clearing behavior.

Do not mark the stage complete until the native-register regression tests pass.

### Stage 19 — git-conflict.nvim

**Status:** Accepted; behavioral acceptance pending.

| Plugin | Intended role | Policy |
|---|---|---|
| git-conflict.nvim | Merge-conflict highlighting, navigation, and resolution | Accepted; integrate with existing Git workflows |

The plugin provides conflict-region highlighting, navigation between conflicts, and commands for selecting conflict-resolution outcomes.

It complements Gitsigns and Diffview rather than replacing them.

**Keymap ownership:**

- `<leader>gc*` is reserved for conflict workflows.
- `]x` and `[x` provide conflict navigation.
- Conflict quickfix and refresh operations must have explicit project-owned mappings.
- Existing `<leader>g*` Git mappings must remain intact.

**Acceptance tests:**

- Verify installation and health checks.
- Verify conflict highlighting.
- Navigate between conflict regions.
- Resolve conflicts using ours, theirs, both, and neither.
- Verify conflict refresh and quickfix behavior.
- Confirm that Gitsigns and Diffview mappings still work.

Do not mark the stage complete until all resolution paths have been tested.

### Stage 20 — octo.nvim

**Status:** Accepted; runtime acceptance pending.

| Plugin or dependency | Intended role | Policy |
|---|---|---|
| octo.nvim | GitHub issues, pull requests, and review workflows | Accepted |
| GitHub CLI (`gh`) | Authenticate and communicate with GitHub | External dependency |
| plenary.nvim | Required Lua utility dependency | Shared dependency; avoid duplicate installations |

Octo integrates GitHub workflows into Neovim. It does not replace Git, Gitsigns, or Diffview.

The GitHub CLI is installed and authenticated. Its availability must also be verified from the Neovim process environment.

**Acceptance tests:**

- Verify `gh` is executable from Neovim.
- Verify Octo health checks.
- List issues.
- List pull requests.
- Open an issue or pull request.
- Verify the configured Snacks picker integration.
- Confirm that authentication failures produce useful feedback.

Do not expose tokens or authentication credentials in configuration files or logs.

### Stage 21 — nvim-ts-autotag

**Status:** Accepted; tests passed.

| Plugin | Intended role | Policy |
|---|---|---|
| nvim-ts-autotag | Automatically close and rename supported tags | Accepted and validated |

The plugin provides tag-closing and tag-renaming behavior for supported Tree-sitter filetypes.

Its configuration enables closing and renaming while keeping close-on-slash disabled.

**Validation:** Installation, configuration, and the reported acceptance tests passed.

The plugin depends on the existing Tree-sitter integration. It must not introduce a second parser-management architecture.

### Stage 22 — trouble.nvim

**Status:** Accepted; tests passed.

| Plugin | Intended role | Policy |
|---|---|---|
| trouble.nvim | Structured diagnostics, symbols, locations, and TODO views | Accepted and validated |

Trouble provides a structured interface for workspace diagnostics, buffer diagnostics, document symbols, LSP locations, location lists, quickfix lists, and TODO annotations.

It complements native diagnostics and the existing Snacks and fzf-lua picker workflows.

**Validation:** Keymap registration and the reported behavioral tests passed.

### Stage 23 — harpoon

**Status:** Accepted; behavioral acceptance pending.

| Plugin or dependency | Intended role | Policy |
|---|---|---|
| harpoon | Quick navigation among explicitly selected project files | Accepted |
| plenary.nvim | Required dependency | Shared dependency; activate explicitly where required |

Harpoon provides a focused file-marking and navigation workflow.

Its project behavior must remain compatible with the existing project.nvim configuration:

- `manual_mode = true`
- `autochdir = false`
- `scope_chdir = "global"`

Do not introduce a second automatic project-root or working-directory manager.

**Acceptance tests:**

- Add the current file.
- Open and inspect the Harpoon menu.
- Select marked files.
- Verify persistence.
- Switch projects and verify list separation where supported by the configured workflow.
- Confirm that project.nvim working-directory behavior remains unchanged.

Keymap registration has been checked. That does not establish full behavioral acceptance.

### Stage 24 — lualine.nvim

**Status:** Accepted; visual acceptance pending.

| Plugin | Intended role | Policy |
|---|---|---|
| lualine.nvim | Statusline presentation | Accepted |

Lualine owns the statusline. It displays selected mode, Git, diagnostics, filename, file format, filetype, progress, and cursor location information.

The configuration uses a text-oriented presentation and does not require Nerd Font icons.

**Acceptance tests:**

- Verify mode display.
- Verify Git branch and diff information.
- Verify diagnostic counts.
- Verify active and inactive split-window behavior.
- Verify colorscheme compatibility.
- Confirm that Lualine does not interfere with Bufferline or Noice.

Installation and configuration inspection have been completed. Visual acceptance remains outstanding.

### Stage 25 — bufferline.nvim

**Status:** Accepted; behavioral acceptance pending.

| Plugin | Intended role | Policy |
|---|---|---|
| bufferline.nvim | Buffer navigation and tabline presentation | Accepted |

Bufferline owns the buffer tabline. It must not be treated as a replacement for native windows or project sessions.

The configured workflow uses buffer ordinals, navigation, selection, and close-picking.

**Acceptance tests:**

- Open several buffers.
- Navigate between buffers.
- Select buffers by ordinal.
- Verify buffer picking and close-picking.
- Verify modified-buffer indicators.
- Verify LSP diagnostic indicators.
- Confirm coexistence with Lualine.
- Confirm that closing a buffer does not produce unexpected window or project behavior.

Keymap registration has been verified. Behavioral acceptance remains outstanding.

### Stage 26 — zen-mode.nvim

**Status:** Accepted; behavioral acceptance pending.

| Plugin | Intended role | Policy |
|---|---|---|
| zen-mode.nvim | Focused editing layout | Accepted |

Zen Mode provides a temporary focused editing layout. It must not become a second window-management or terminal-management system.

The configuration uses a centered editing window and temporarily adjusts selected display options.

**Acceptance tests:**

- Enter Zen Mode.
- Exit Zen Mode using the toggle and explicit close mapping.
- Verify window width and layout.
- Verify restoration of editor options.
- Verify interaction with Lualine and Bufferline.
- Verify that diagnostics, terminal workflows, and project navigation remain usable.

### Stage 27 — noice.nvim

**Status:** Accepted; tests passed.

| Plugin or dependency | Intended role | Policy |
|---|---|---|
| noice.nvim | Enhanced command-line, messages, and LSP progress presentation | Accepted and validated |
| nui.nvim | UI component dependency | Required dependency |
| Native Neovim UI | Completion, notifications, input, and selection | Retained as the default owner |

The accepted UI architecture is **Noice full integration with native completion and native notifications**.

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

Do not install `nvim-notify` or introduce Telescope to support this architecture.

Lualine, Bufferline, Trouble, Snacks, and fzf-lua retain their separate responsibilities.

**Validation:** The reported acceptance tests passed.

### Stage 28 — vim-illuminate

**Status:** Accepted; tests passed.

| Plugin | Intended role | Policy |
|---|---|---|
| vim-illuminate | Highlight symbol references under the cursor | Accepted and validated |

The plugin provides symbol-reference highlighting using LSP, Tree-sitter, and regex providers.

The native LSP configuration was audited before adoption. The inspected repository configuration did not contain a competing native document-highlight workflow.

The accepted configuration:

- Uses LSP, Tree-sitter, and regex providers.
- Uses a 150 ms delay.
- Disables plugin-default keymaps.
- Uses project-owned mappings.
- Applies a large-file cutoff.

The project-owned mappings use the existing UI namespace:

- `<leader>ui` — Toggle symbol highlighting.
- `<leader>un` — Next symbol reference.
- `<leader>up` — Previous symbol reference.

**Validation:** The user confirmed that the acceptance tests passed.

---

## Current Plugin Acceptance Summary

This summary records the latest reported acceptance results. It is not a substitute for repository inspection.

| Stage | Plugin | Admission | Implementation | Acceptance |
|---:|---|---|---|---|
| 17 | nvim-spider | Accepted | Implemented | Pending behavioral tests |
| 18 | yanky.nvim | Accepted | Implemented | Pending behavioral tests |
| 19 | git-conflict.nvim | Accepted | Implemented | Pending behavioral tests |
| 20 | octo.nvim | Accepted | Implemented | Pending runtime tests |
| 21 | nvim-ts-autotag | Accepted | Implemented | Passed |
| 22 | trouble.nvim | Accepted | Implemented | Passed |
| 23 | harpoon | Accepted | Implemented | Pending behavioral tests |
| 24 | lualine.nvim | Accepted | Implemented | Pending visual tests |
| 25 | bufferline.nvim | Accepted | Implemented | Pending behavioral tests |
| 26 | zen-mode.nvim | Accepted | Implemented | Pending behavioral tests |
| 27 | noice.nvim | Accepted | Implemented | Passed |
| 28 | vim-illuminate | Accepted | Implemented | Passed |

**Acceptance rule:** Do not mark a stage complete until the corresponding behavioral, visual, or runtime tests have passed. Keymap registration and plugin loading are necessary checks, not complete acceptance criteria.

### Shared dependency: plenary.nvim

`plenary.nvim` is a shared dependency used by selected integrations, including Harpoon and Octo.

It must be installed once and activated according to the dependency requirements of the consuming plugins. Do not create duplicate plugin declarations for the same repository.

---

## Deferred and Rejected Candidates

The following decisions must remain explicit rather than being inferred from another distribution's plugin list.

| Candidate | Current direction | Admission condition |
|---|---|---|
| Mason | Not selected as the default tool manager | Reconsider only if a documented requirement outweighs the separate-tool-management policy |
| nvim-web-devicons | Not selected | Do not add without a concrete unmet requirement |
| render-markdown.nvim | Optional alternative | Adopt only if the in-buffer rendering workflow is explicitly required |
| markdown-preview.nvim | Optional browser-preview extension | Adopt only after independent dependency, configuration, keymap, and workflow validation |
| mini.hipatterns | Candidate | Confirm a concrete requirement and stage assignment before admission |
| Additional Markdown or PDF workflow plugins | Future candidates | Evaluate when the relevant workflow requirements are defined |
| nvim-dap | Deferred | Reopen only when the debugging stage is explicitly approved |
| neotest | Not selected for the current roadmap | Reconsider only after a concrete testing workflow requirement is documented |

`project.nvim` is no longer a deferred candidate. Its admission has been accepted for Stage 12, and its implementation and core project-navigation behavior have been tested. Its presence in the implementation does not make Stage 12 complete.

`nvim-lspconfig` is not a deferred candidate because its admission has been accepted for Stage 09. Its implementation and runtime validation are part of the completed Stage 09 foundation.

`zen-mode.nvim` is no longer deferred. It has been accepted for Stage 26, although its behavioral acceptance tests remain outstanding.

A deferred candidate is not necessarily rejected for all circumstances. It is not admitted into the current implementation without further evaluation.

---

## Future Roadmap Stages

The following stages retain the previous roadmap objectives while avoiding conflicts with the newly established plugin stages.

### Stage 29 — Final Integration and Regression Testing

**Status:** Planned.

This stage consolidates the accepted plugin integrations and verifies their behavior together.

Requirements:

- Complete all outstanding acceptance tests from Stages 17–28.
- Verify shared dependencies and plugin load order.
- Check global and buffer-local keymap collisions.
- Verify Git, navigation, editing, and UI integrations together.
- Run syntax, formatting, smoke, and regression checks.
- Verify the supported Neovim versions.
- Update architecture and plugin documentation.
- Remove unused or duplicate plugin declarations.

This stage does not automatically introduce new plugins.

### Stage 30 — Performance and Lazy Loading

**Status:** Planned.

Evaluate startup and runtime behavior before introducing lazy loading.

Requirements:

- Establish a validated eager-loading baseline.
- Measure startup performance before making changes.
- Introduce lazy loading only where measurements justify it.
- Preserve explicit plugin ownership and deterministic loading behavior.
- Verify commands, events, dependencies, and user workflows after each change.
- Avoid introducing lazy-loading complexity without measurable benefit.

### Stage 31 — Release Preparation

**Status:** Planned.

This stage covers documentation consistency, dependency review, regression testing, and release preparation.

Requirements:

- Verify that repository documentation matches the implementation.
- Confirm external dependency requirements and supported versions.
- Review platform installation instructions.
- Run the full validation suite.
- Check repository cleanliness and generated artifacts.
- Record known limitations and outstanding issues.
- Prepare release notes and version information.

New dependencies discovered during release preparation must follow the normal admission process.

---

## Repository Verification

Before changing an item's status, inspect the actual repository and validate the relevant behavior.

Use this verification sequence:

1. Confirm whether the plugin is declared in the plugin-management configuration.
2. Confirm whether its setup module exists and is loaded.
3. Check whether shared and external dependencies are documented.
4. Run applicable syntax, formatting, and smoke checks.
5. Perform interactive verification when headless tests cannot establish the behavior.
6. Confirm that keymaps and user-facing commands match the implementation.
7. Verify that the plugin does not duplicate an existing native or plugin workflow.
8. Update the inventory and related documentation to match the verified result.

Do not infer installation from an inventory entry or completion from a commit message alone.

For optional plugins, distinguish an accepted architectural option from an installed dependency. An optional plugin must not be described as implemented unless it has actually been added and configured.

### Acceptance evidence

Use the following distinctions when recording test results:

| Evidence | What it establishes |
|---|---|
| Plugin declaration | The repository requests the plugin |
| Setup module | Configuration exists |
| Normal startup | The plugin loads through the intended entry point |
| Health check | Supported health checks pass |
| Keymap inspection | Expected mappings are registered |
| Behavioral test | The feature works interactively |
| Regression test | Existing workflows remain intact |
| Stage acceptance | All defined stage criteria are satisfied |

A stage may require several types of evidence. Record the actual result rather than inferring it from a single successful check.

---

## Related Documentation

- `README.md` — project overview, installation, current status, and roadmap summary.
- `docs/architecture.md` — architectural principles and module boundaries.
- `docs/roadmap.md` — stage order and completion criteria.
- `docs/dependencies.md` — external tools and dependency requirements.
- `docs/Keymap-test.md` — interactive keymap verification.
- `docs/win-install.md` — Windows installation guidance.
- `docs/markdown-support.md` — Markdown and MDX support, rendering, linting, formatting, and preview workflows.

As the project grows, update this inventory alongside plugin admission decisions and stage implementation rather than allowing it to become a separate, aspirational plugin list.
