# Native Keymap Testing

This document defines the interactive validation procedures for the native terminal-mode and commenting workflows in `nvim-config`.

The goal is to verify Neovim's built-in behavior and the project's existing keymaps before changing the implementation or introducing plugins.

## 1. Native Terminal Workflow

The configuration registers a custom `Esc Esc` mapping intended to leave Terminal mode and return to Normal mode without closing the terminal buffer.

### Interactive validation

Before changing the implementation, verify the workflow in a real Neovim session.

1. Open Neovim using the project configuration:

   ```powershell
   nvim -u init.lua
   ```

2. Open a terminal using the built-in command:

   ```vim
   :terminal
   ```

3. Type a simple command and confirm that it executes. For PowerShell, use:

   ```powershell
   Write-Output "Terminal workflow works"
   ```

4. Press `Esc` twice. Confirm that Neovim returns to Normal mode while keeping the terminal buffer open.
5. Enter Terminal mode again, type another command, and verify that the terminal remains usable.
6. Compare the result with Neovim's built-in Terminal-mode escape sequence: press `Ctrl-\` followed by `Ctrl-n`.
7. If `Esc Esc` fails, record the exact behavior. Do not change the mapping until the failure has been reproduced and the cause investigated.

### Expected result

The terminal executes commands, `Esc Esc` returns Neovim to Normal mode, and the terminal buffer remains open and usable.

### Automated verification

The smoke test checks that the terminal mapping exists and that its right-hand side and description match the configuration.

These assertions verify mapping registration, not whether the mapping behaves correctly during interactive use.

### Current status

The interactive test passed. Pressing `Esc Esc` returned Neovim to Normal mode while keeping the terminal buffer open. The terminal remained available.

The command entered during testing contained a typo, but this did not affect the observed Terminal-mode mapping behavior.

**Status: Passed — interactive behavior verified.**

## 2. Native Commenting Workflow

Neovim 0.12 provides built-in commenting mappings:

- `gcc` toggles a comment on the current line.
- `gc` toggles comments for a motion or Visual-mode selection.

The project should use Neovim's native commenting behavior rather than introduce a commenting plugin.

### Inspect the current implementation

1. Open `lua/config/keymaps.lua`.
2. Locate the native commenting-related configuration.
3. Check for custom mappings that could override or interfere with Neovim's built-in behavior.
4. Open a Lua file and inspect its filetype and comment string:

   ```vim
   :set filetype?
   :set commentstring?
   ```

For Lua, the expected comment string is:

```text
-- %s
```

Record the actual values if they differ from the expected values.

### Interactive validation

1. Open a Lua file and place the cursor on a line of code.
2. Press `gcc` to toggle the line comment.
3. Press `gcc` again to uncomment the line.
4. Select multiple lines in Visual mode and press `gc` to toggle their comments.
5. Repeat the checks in a filetype with different comment syntax, such as PowerShell.
6. Confirm that comments are applied and removed correctly for both individual lines and selections.
7. If any operation fails, record the exact command, filetype, observed behavior, and expected behavior before changing the configuration.

### Diagnostic findings

The following observations have been collected during investigation:

- **Clean-session comparison:** `gcc` works in `nvim --clean`.
- **Configured-session mappings:** `gcc` and `gc` are registered as Lua callback mappings with the expected descriptions, `Toggle comment line` and `Toggle comment`.
- **Lua comment syntax:** The configured Lua buffer reports `filetype=lua` and `commentstring=-- %s`. Neovim identifies the Lua filetype plugin as the source of the comment string.
- **Operator function:** `operatorfunc` is empty. This observation alone does not establish a fault.
- **Configured Lua-buffer test:** In a disposable Lua buffer under the project configuration, pressing `gcc` left the line unchanged.
- **Visual commenting:** An earlier Visual-mode `gc` test behaved unexpectedly, so selection commenting remains unverified.

These findings establish a difference between the clean and configured sessions, but they do not identify its cause. The mapping metadata confirms registration; it does not prove that the callback completes the intended commenting operation.

### Expected result

The built-in mappings comment and uncomment the intended lines or selections using the appropriate syntax for each filetype.

### Automated verification

The smoke test reports `PASS native commenting`. This result does not, by itself, establish that the commenting actions work interactively.

### Current status

Automated smoke checks pass, but interactive testing has identified a failure in the configured session. The cause has not been established.

The investigation is deferred pending further research. No replacement mappings or commenting plugins should be introduced merely to work around the unresolved behavior.

**Status: Deferred and unresolved.**

Do not consider native commenting functional until the interactive behavior has been investigated and verified. Do not introduce self-referential mappings as a substitute for a correct implementation.

## 3. Recording Test Results

Record the outcome of each interactive test independently. Do not mark a test as passed solely because its mapping exists or an automated assertion succeeds.

| Workflow | Automated check | Interactive result |
|---|---|---|
| Terminal escape (`Esc Esc`) | Mapping registration and properties checked | **Passed** — returned to Normal mode; terminal buffer remained open |
| Native line commenting (`gcc`) | Smoke test reports `PASS native commenting` | **Failed in configured session** — works in `nvim --clean`, but had no visible effect in a configured Lua buffer |
| Native selection commenting (`gc`) | Smoke test reports `PASS native commenting` | **Unresolved** — previously behaved unexpectedly; requires further investigation |

After testing, update this table with the observed result and revise the corresponding status section. If a test fails, retain the unresolved status until the cause has been investigated and the expected behavior verified.

## 4. Validation Policy

- Verify behavior in a real Neovim session before changing the implementation.
- Distinguish mapping registration and automated smoke-test results from actual interactive behavior.
- Record each interactive test as passed, failed, or not yet tested.
- Investigate failures before changing the configuration.
- Add automated regression assertions for stable, testable behavior when appropriate.
- Do not introduce a plugin merely to avoid investigating an existing native workflow.
- Keep unresolved behavior documented until it is reproduced, understood, and verified after any correction.

## 5. Outstanding Follow-ups

1. Resume the native commenting investigation after further research.
2. Determine why `gcc` works in `nvim --clean` but has no visible effect in a configured Lua buffer.
3. Verify native selection commenting (`gc`) independently.
4. Update this document with diagnostic findings and verified results after the investigation resumes.

The terminal escape workflow is verified. Native commenting remains unresolved, and its investigation is deferred.

**Stage 04 remains in progress until its acceptance criteria are satisfied.**
