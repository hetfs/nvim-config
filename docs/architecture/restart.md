---
title: Restart and Session Workflow
description: Documentation for Neovim restart, session resume, and last Ex command execution.
---

# Restart and Session Workflow

The `lua/config/restart.lua` module provides lightweight workflow helpers for restarting Neovim, resuming a session, and rerunning the last Ex command.

It follows the configuration's native-first architecture and keeps responsibilities separate:

- `lua/config/restart.lua` implements workflow functions.
- `lua/config/keymaps.lua` owns all keybindings.
- `mini.sessions` provides session restoration when configured.

The module does not implement its own keybinding system, session manager, or configuration reload mechanism.

## Design Principles

### Functions-only module

The module exposes functions through a Lua table. It does not register keymaps or create autocommands.

This keeps workflow implementation separate from user interaction and ensures that keybindings remain centralized in `lua/config/keymaps.lua`.

### Native Neovim functionality

The module uses Neovim's built-in APIs wherever possible:

| Operation | Implementation |
|---|---|
| Restart | Native `:restart` command |
| Resume session | `mini.sessions` |
| Rerun command | Ex command history and `vim.cmd()` |
| Notifications | `vim.notify()` |
| Confirmation | `vim.ui.select()` |

No additional plugin is introduced for these operations.

## Module Location

```text
lua/
└── config/
    ├── keymaps.lua
    └── restart.lua
```

The module is loaded from the centralized keymap configuration.

## Public API

### `restart()`

Restarts the current Neovim instance using the native `:restart` command.

```lua
require("config.restart").restart()
```

The command delegates restart behavior to Neovim instead of implementing a custom shutdown and startup sequence.

If the command raises an error, the module reports it through `vim.notify()`.

Modified buffers remain subject to Neovim's normal write-protection behavior.

### `resume()`

Restores a session through `mini.sessions`.

```lua
require("config.restart").resume()
```

The function loads `mini.sessions` when needed and calls its `read()` function.

If the module is unavailable or session restoration raises an error, the user receives an error notification.

Session restoration depends on the installed `mini.sessions` configuration and its available session files.

### `rerun_last_command()`

Retrieves the most recent Ex command from Neovim's command history and asks the user to confirm execution.

```lua
require("config.restart").rerun_last_command()
```

The implementation uses:

```lua
local command = vim.fn.histget(":", -1)
```

The confirmation dialog provides two choices:

- **Run:** Execute the retrieved command.
- **Cancel:** Exit without executing it.

The command is executed using:

```lua
vim.cmd(command)
```

If no previous Ex command exists, the module displays a warning.

The confirmation step helps prevent accidental execution of commands that modify files, buffers, or the editor state.

## Keybindings

All keybindings are registered in `lua/config/keymaps.lua`.

| Mapping | Action | Description |
|---|---|---|
| `<leader>R` | Keymap group | Restart workflow |
| `<leader>Rr` | `restart()` | Restart Neovim |
| `<leader>Rs` | `resume()` | Resume session |
| `<leader>Rl` | `rerun_last_command()` | Rerun last Ex command |

The `<leader>R` mapping is registered as `<Nop>` to establish the which-key group.

The mappings use uppercase `R` to avoid conflicts with existing lowercase `<leader>r*` mappings.

## Integration

Add the following section to `lua/config/keymaps.lua` before its final `return M` statement:

```lua
-- ============================================================
-- Restart / Resume / Rerun
-- ============================================================

local restart = require("config.restart")

map("n", "<leader>R", "<Nop>", {
  desc = "+restart",
})

map("n", "<leader>Rr", restart.restart, {
  desc = "Restart: Restart Neovim",
})

map("n", "<leader>Rs", restart.resume, {
  desc = "Restart: Resume session",
})

map("n", "<leader>Rl", restart.rerun_last_command, {
  desc = "Restart: Rerun last Ex command",
})
```

This assumes `map` is the existing local reference to `vim.keymap.set`. Otherwise, use `vim.keymap.set` directly.

No additional changes to `init.lua` are required.

## Error Handling

The module uses protected calls with `pcall()` around operations that can fail.

| Operation | Failure condition | Expected behavior |
|---|---|---|
| Restart | Native restart command fails | Error notification |
| Resume | `mini.sessions` cannot load | Error notification |
| Resume | Session restoration raises an error | Error notification |
| Rerun | No previous Ex command exists | Warning notification |
| Rerun | Command execution fails | Error notification |

Notifications use the `Restart` title to identify their source.

## Validation

Run the following commands inside Neovim to verify that the module exposes its expected functions:

```vim
:lua local m = require("config.restart"); assert(type(m.restart) == "function"); assert(type(m.resume) == "function"); assert(type(m.rerun_last_command) == "function")
```

Verify the keybindings:

```vim
:verbose nmap <leader>R
:verbose nmap <leader>Rr
:verbose nmap <leader>Rs
:verbose nmap <leader>Rl
```

### Functional tests

| Test | Procedure | Expected result |
|---|---|---|
| Restart | Press `<leader>Rr` | Neovim restarts |
| Restart with modifications | Modify a buffer and restart | Normal write protection applies |
| Resume | Press `<leader>Rs` with a saved session | Session restoration is attempted |
| Resume without a session | Press `<leader>Rs` without a saved session | Behavior follows the installed `mini.sessions` implementation |
| Rerun | Execute `:pwd`, then press `<leader>Rl` | Confirmation appears and `:pwd` runs when selected |
| Cancel rerun | Select Cancel | Previous command is not executed |

## Scope and Limitations

This module intentionally has a narrow scope.

It does not:

- Reload the entire configuration by sourcing `init.lua`.
- Clear `package.loaded` or reload already-loaded Lua modules.
- Replace `mini.sessions` with a custom session manager.
- Maintain a separate command history.
- Automatically execute the last Ex command without confirmation.
- Register keybindings outside `lua/config/keymaps.lua`.

A configuration restart should use Neovim's native restart functionality rather than a partial reload that may leave previously loaded modules and autocommands in an inconsistent state.

## Compatibility

The module targets Neovim 0.12 or later because it uses the native `:restart` command.

Session restoration also requires `mini.sessions` to be installed and configured.

## Summary

`lua/config/restart.lua` provides three focused workflow operations:

1. Restart Neovim.
2. Resume a saved session.
3. Rerun the last Ex command with confirmation.

The implementation preserves the project's modular architecture, keeps keybindings centralized, and relies on native Neovim functionality wherever possible.
