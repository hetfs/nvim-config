# Keymaps

## Purpose

This document is the reference for the user-facing keymaps provided by `nvim-config`.

User-facing keymaps should be centralized in `lua/config/keymaps.lua` and include a descriptive `desc` field. Plugin-specific mappings should be registered through the central keymap module rather than scattered across plugin configuration files.

The project follows a native-first approach: Neovim's built-in capabilities take priority, and external plugins are added only when they provide a justified benefit.

> **Minimum installation. Compose the rest.**

## Leader Key

The leader key is the prefix for custom workflows.

The current configuration uses:

| Key | Value |
|---|---|
| Leader | `<Space>` |
| Local leader | `\` |

Consult `lua/config/keymaps.lua` for the authoritative definitions and descriptions.

## Native Workflows

Native Neovim mappings and workflows remain the default wherever built-in functionality is sufficient.

Custom mappings must use the `desc` field so their purpose can be inspected through Neovim and mapping-discovery tools.

Shared native workflows should not be duplicated by language-specific or plugin-specific mappings.

### Terminal Workflows

Terminal management uses Neovim's built-in terminal support.

| Mapping | Description | Action | Scope |
|---|---|---|---|
| `<leader>tq` | Close terminal window | Close the current terminal window. | Global normal-mode mapping with a terminal-buffer guard. |

The terminal-close mapping checks the current buffer type before closing the window. If the current buffer is not a terminal, it displays a warning and leaves the window open.

This guard prevents the mapping from accidentally closing ordinary editing windows.

## LSP Workflows

Shared LSP mappings are registered through the central keymap module when an LSP client attaches to a buffer.

| Mapping | Description | Action |
|---|---|---|
| `<leader>cd` | LSP: Diagnostics float | Show diagnostics for the current line or buffer. |
| `<leader>cq` | LSP: Diagnostics quickfix | Populate the quickfix list with diagnostics. |
| `<leader>ck` | LSP: Signature help | Request signature help from the attached language server. |
| `<leader>ca` | LSP: Code action | Request available code actions. |

These mappings are buffer-local and depend on an LSP client attaching to the buffer.

Language-specific mappings should not redefine these shared LSP actions.

## Git Workflows

Git hunk mappings are provided by Gitsigns and registered through the central keymap module. These mappings are buffer-local and become available for buffers where Gitsigns attaches.

| Mapping | Description | Action |
|---|---|---|
| `<leader>ghs` | Git: Stage hunk | Stage the hunk under the cursor. |
| `<leader>ghr` | Git: Reset hunk | Reset the hunk under the cursor. |
| `<leader>ghp` | Git: Preview hunk | Preview the hunk under the cursor. |
| `<leader>ghb` | Git: Blame line | Show Git blame information for the current line. |
| `<leader>ghd` | Git: Diff buffer | Show the buffer's Git diff. |

These mappings require Gitsigns to be installed and attached to the current buffer. Their availability may depend on the buffer being part of a Git repository and containing relevant Git changes.

## Project Navigation

Project root detection and project navigation are provided by `project.nvim`.

The project workflow supports detecting project roots and navigating between projects. Use the `:Project` command for the plugin's project-selection workflow.

The current configuration uses explicit project navigation. Automatic directory changes are disabled, so project detection does not implicitly change Neovim's working directory.

Project navigation is separate from language-specific project commands. For example, CMake build and run operations use the CMake project root without requiring an automatic working-directory change.

## Session Management

Session management is provided by `mini.sessions`, using the existing shared `mini.nvim` installation.

Session operations are explicit: saving, restoring, and deleting a session require a user action. Automatic session reads and writes are disabled in the current configuration.

| Mapping | Description | Action |
|---|---|---|
| `<leader>qs` | Session: Restore | Select and restore a saved session. |
| `<leader>qw` | Session: Save | Select a session name and save the current session. |
| `<leader>qd` | Session: Delete | Select and delete a saved session. |

Session operations use the `mini.sessions` selection interface. The configured session filename is `Session.vim`; the selection interface allows the user to choose the session to operate on.

The configuration does not force session reads, writes, or deletions. Review the selected operation and session before confirming it.

## Fuzzy Finding

The fzf-lua mappings remain independent of Snacks Picker configuration.

| Mapping | Description | Action |
|---|---|---|
| `<leader>pr` | Resume | Resume the previous fzf-lua picker operation. |

Do not repurpose `<leader>pr` as part of project navigation. Project navigation and fzf-lua's resume workflow serve different purposes.

Snacks Picker and fzf-lua retain independent configuration and mapping definitions.

## C and C++ Workflows

C and C++ use independent language packs with shared CMake and clangd infrastructure.

The following mappings are registered as buffer-local mappings for C and C++ buffers.

| Mapping | Description | Action |
|---|---|---|
| `<leader>cb` | C/C++: Build | Run the CMake build for the detected project. |
| `<leader>cr` | C/C++: Run | Prompt for an executable and run it in a terminal. |
| `<leader>ch` | C/C++: Switch header/source | Ask clangd to switch between the current source and header file. |

### CMake build

`<leader>cb` invokes the shared CMake build workflow.

The workflow:

- Detects the outermost ancestor containing `CMakeLists.txt`.
- Uses the project's `build/` directory.
- Runs `cmake --build` from the detected project root.
- Reports build failures and displays parsed compiler diagnostics in the quickfix list when available.

CMake configuration is explicit. If the build directory does not exist, configure the project first:

```powershell
cmake -S . -B build
```

The mapping does not silently configure or regenerate a project.

### CMake run

`<leader>cr` prompts for an executable path.

The workflow resolves relative paths against the CMake project root, validates the selected executable, and launches it in a terminal split.

The mapping does not assume a fixed executable name or automatically select an arbitrary build output.

### Header and source navigation

`<leader>ch` invokes clangd's `textDocument/switchSourceHeader` extension.

The workflow checks for an attached clangd client and handles unsupported requests, request errors, and cases where no matching file is available.

The mapping is buffer-local and does not replace ordinary file navigation.

## Rust Workflows

Rust mappings are registered independently from C/C++ mappings and are buffer-local to Rust buffers.

| Mapping | Description | Action |
|---|---|---|
| `<leader>cb` | Rust: Build | Run the Cargo build workflow. |
| `<leader>cr` | Rust: Run | Run the current Cargo project. |
| `<leader>ct` | Rust: Test | Run the Cargo test workflow. |
| `<leader>cc` | Rust: Check | Run the Cargo check workflow. |

These mappings are provided by the Rust language integration.

## Python Workflows

Python mappings are registered through the central keymap module and are buffer-local to Python buffers.

| Mapping | Description | Action |
|---|---|---|
| `<leader>cr` | Python: Run file | Run the current Python file. |
| `<leader>ct` | Python: Run tests | Run `python -m pytest` from the detected project root. |
| `<leader>cc` | Python: Type check | Run `ty check .` from the detected project root. |
| `<leader>cl` | Python: Lint file | Run Ruff against the current file. |

### Python interpreter resolution

The run-file and test mappings resolve the Python interpreter in this order:

1. Project `.venv`.
2. Active environment from `VIRTUAL_ENV`.
3. System Python.

On Windows, the project interpreter is resolved from `.venv\Scripts\python.exe`. On Unix-like systems, the expected path is `.venv/bin/python`.

If neither a project environment nor an active environment is available, the workflow falls back to the system Python executable. The fallback is reported to the user.

### Python project root

The Python workflow detects the project root using these markers:

- `pyproject.toml`
- `pytest.ini`
- `tox.ini`
- `setup.cfg`
- `setup.py`
- `requirements.txt`
- `Pipfile`
- `uv.lock`
- `poetry.lock`
- `.git`

The nearest ancestor matching a marker is used. If no marker is found, the current file's directory is used.

This root detection belongs to the Python keymap workflow. It does not replace or modify the root detection policies used by language servers or other project integrations.

### Type checking and linting

`<leader>cc` runs `ty check .` from the detected Python project root.

`<leader>cl` runs Ruff against the current file.

The Ty and Ruff executables are resolved independently through `PATH`. These mappings do not invoke `uv run` or automatically install tools. If Ty or Ruff is installed only inside a project environment, its executable directory must be available through Neovim's `PATH`.

### Terminal execution

Python run and test workflows execute in a terminal split using the detected project root as the working directory.

The mappings do not change Neovim's global working directory.

## Language Mapping Isolation

Some mappings intentionally share key sequences across languages:

| Mapping | C/C++ action | Rust action | Python action |
|---|---|---|---|
| `<leader>cb` | CMake build | Cargo build | — |
| `<leader>cr` | CMake run | Cargo run | Run current file |
| `<leader>ct` | — | Cargo test | Run pytest |
| `<leader>cc` | — | Cargo check | Run Ty |
| `<leader>cl` | — | — | Run Ruff |

This overlap is intentional. The mappings are buffer-local and registered for their respective filetypes, so the active language determines the action.

Do not make these mappings global or register unrelated language workflows on the same buffer.

## Shared Formatting

Formatting uses the shared `<leader>cf` mapping.

| Mapping | Description | Action |
|---|---|---|
| `<leader>cf` | Format: Format buffer | Invoke the configured formatting workflow. |

The mapping is shared across supported languages. Language packs provide formatter metadata; they should not introduce duplicate formatting mappings.

Format-on-save is disabled by default. Formatting remains an explicit user action unless the configuration is deliberately changed.

## Optional External Workflows

Some workflows depend on external executables rather than Neovim plugins.

### Lazygit

Lazygit is an optional external executable, not a Neovim plugin. The configuration must not assume it is installed.

If a lazygit mapping is provided, it must check whether the executable is available before attempting to launch it. If unavailable, show a clear warning rather than failing silently.

External tools are managed separately from Neovim plugin installation. Refer to `docs/dependencies.md` for the project's dependency policy.

## Mapping Conventions

- Keep user-facing mappings centralized in `lua/config/keymaps.lua`.
- Give custom mappings a meaningful `desc` field.
- Use buffer-local mappings for workflows specific to a buffer, filetype, or plugin attachment.
- Keep language-specific mappings isolated by filetype.
- Preserve intentional mapping overlaps only when their buffer-local scope makes the behavior unambiguous.
- Keep shared LSP and formatting mappings separate from language-specific workflows.
- Keep plugin configuration and mapping registration separate where practical.
- Do not duplicate plugin installation or setup merely to register a mapping.
- Keep Snacks Picker and fzf-lua configuration independent.
- Check for optional external executables before invoking them.
- Prefer explicit actions over unexpected automatic changes, particularly for session and build workflows.
- Update this document whenever a user-facing mapping is added, removed, or renamed.

## Verification

This document describes the intended mapping reference; it does not replace interactive testing.

Use `docs/Keymap-test.md` for interactive keymap and workflow testing procedures. That document covers validation steps and observed behavior, while this file serves as the mapping reference.

The current implementation should be checked against `lua/config/keymaps.lua` and `lua/config/autocmds.lua` whenever mappings or filetype registrations change.

For language-specific workflows, verify both the mapping and its real project behavior. In particular:

- Test C/C++ mappings inside a configured CMake project.
- Test Rust mappings inside a Cargo project.
- Test Python mappings inside a Python project with and without a project virtual environment.
- Confirm that overlapping C/C++, Rust, and Python mappings remain buffer-local and isolated.
- Confirm that shared LSP and formatting mappings remain available independently of language-specific mappings.
- Confirm that `<leader>tq` closes terminal windows but does not close ordinary editing windows.
- Confirm that optional external tools fail with a clear warning when unavailable.

Automated tests validate mapping registration, buffer scope, and selected workflow behavior. Interactive tests remain necessary for verifying the complete user experience.
