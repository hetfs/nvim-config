# Keymaps

## Purpose

This document is the reference for the user-facing keymaps provided by `nvim-config`.

All user-facing keymaps should be centralized in `lua/config/keymaps.lua` and include a descriptive `desc` field. Plugin-specific mappings should be registered through the central keymap module rather than scattered across plugin configuration files.

The project follows a native-first approach: Neovim's built-in capabilities take priority, and external plugins are added only when they provide a justified benefit.

> **Minimum installation. Compose the rest.**

## Leader Key

The leader key is used as the prefix for custom workflows. Consult `lua/config/keymaps.lua` for the authoritative definitions and descriptions.

## Native Workflows

Native Neovim mappings and workflows should remain the default wherever built-in functionality is sufficient.

Use the `desc` field for custom mappings so that their purpose can be inspected by Neovim and mapping-discovery tools.

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

Project detection and navigation are separate from changing Neovim's working directory automatically. The current configuration disables automatic directory changes.

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

Snacks Picker and fzf-lua should retain independent configuration and mapping definitions.

## Optional External Workflows

Some workflows depend on external executables rather than Neovim plugins.

### Lazygit

Lazygit is an optional external executable, not a Neovim plugin. The configuration must not assume it is installed.

If a lazygit mapping is provided, it must check whether the executable is available before attempting to launch it. If unavailable, show a clear warning rather than failing silently.

External tools are managed separately from Neovim plugin installation. Refer to `docs/dependencies.md` for the project's dependency policy.

## Mapping Conventions

- Keep user-facing mappings centralized in `lua/config/keymaps.lua`.
- Give custom mappings a meaningful `desc` field.
- Use buffer-local mappings when the workflow is specific to a buffer or plugin attachment, as with Gitsigns.
- Keep plugin configuration and mapping registration separate where practical.
- Do not duplicate plugin installation or setup merely to register a mapping.
- Keep Snacks Picker and fzf-lua configuration independent.
- Check for optional external executables before invoking them.
- Prefer explicit actions over unexpected automatic changes, particularly for session management.

## Verification

The mapping reference documents intended behavior; it does not replace interactive testing.

Use `docs/Keymap-test.md` for the interactive keymap and workflow testing procedures. That document covers validation steps and observed behavior, while this file serves as the mapping reference.

The current implementation should be checked against `lua/config/keymaps.lua` whenever mappings are added, removed, or renamed. Update this document alongside the implementation so that the reference remains accurate.
