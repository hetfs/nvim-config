# Native Keymap and Interactive Workflow Testing

This document defines the testing procedures for native Neovim workflows, project-defined keymaps, and plugin-provided navigation and editing features in `nvim-config`.

Its purpose is to teach a repeatable approach to validating configuration behavior before changing implementations, adding dependencies, or declaring a development stage complete.

The project follows these principles:

- **Minimum installation. Compose the rest.**
- Prefer Neovim's built-in capabilities when they meet the requirement.
- Test actual behavior, not just mapping registration.
- Separate automated verification from interactive verification.
- Investigate failures before changing the implementation.
- Keep unresolved issues documented until they are understood and verified.
- Do not introduce a plugin merely to work around an unexplained native behavior.

## 1. Testing Model

A mapping can exist without performing its intended action. Reliable validation therefore requires several distinct kinds of evidence.

### 1.1 Static and syntax validation

Check that Lua files parse correctly and follow the project's formatting rules.

```powershell
stylua --check .
nvim --headless -u NONE -l scripts/check-syntax.lua
```

These checks identify formatting and syntax problems. They do not prove that a mapping behaves correctly.

### 1.2 Automated smoke testing

Run the project's smoke test with the configuration loaded:

```powershell
nvim --headless -u init.lua -c "luafile scripts/smoke.lua"
```

Smoke tests can verify module loading, mapping registration, descriptions, selected options, and other testable properties.

A successful registration assertion establishes that a mapping exists with the expected metadata. It does not necessarily establish that the callback completes its intended operation.

### 1.3 Interactive testing

Launch a normal Neovim session and perform the workflow manually.

```powershell
nvim -u init.lua
```

Use a disposable buffer for operations that modify text. Observe the actual result, including prompts, cursor movement, buffer state, and errors.

### 1.4 Regression testing

After a change, repeat the relevant test and verify that existing workflows still work.

For example, changing Flash's Treesitter mapping must not remove the existing Normal-mode `S` substitution mapping.

### 1.5 Evidence and status

Record each result independently:

- **Passed:** The expected behavior was observed.
- **Failed:** The behavior was tested and did not match the expectation.
- **Unverified:** The behavior has not been adequately tested.
- **Deferred:** Investigation has deliberately been postponed. Include the reason and outstanding work.

Do not treat a deferred or unverified test as passed.

---

## 2. Native Terminal Workflow

The configuration defines an `Esc Esc` mapping intended to leave Terminal mode and return to Normal mode without closing the terminal buffer.

### 2.1 Interactive procedure

1. Launch Neovim with the project configuration:

   ```powershell
   nvim -u init.lua
   ```

2. Open a terminal using Neovim's built-in command:

   ```vim
   :terminal
   ```

3. Execute a simple command. In PowerShell, use:

   ```powershell
   Write-Output "Terminal workflow works"
   ```

4. Confirm that the command executes and produces the expected output.

5. Press `Esc` twice. Confirm that Neovim returns to Normal mode and that the terminal buffer remains open.

6. Re-enter Terminal mode and execute another command. Verify that the terminal remains usable.

7. Compare the result with Neovim's built-in Terminal-mode escape sequence: press `Ctrl-\` followed by `Ctrl-n`.

8. If the custom mapping fails, record the exact behavior before modifying it.

### 2.2 Expected behavior

- The terminal accepts and executes commands.
- `Esc Esc` returns Neovim to Normal mode.
- The terminal buffer remains open.
- Terminal mode can be entered again and used normally.

### 2.3 Automated verification

The smoke test checks that the terminal mapping is registered and that its right-hand side and description match the configuration.

This validates the mapping definition, not the interactive transition between modes.

### 2.4 Recorded result

The interactive test passed. Pressing `Esc Esc` returned Neovim to Normal mode while preserving the terminal buffer. The terminal remained available.

A typo in a command entered during testing did not affect the observed mapping behavior.

**Status: Passed — interactive behavior verified.**

---

## 3. Native Commenting Workflow

Neovim 0.12 provides built-in commenting mappings. The project intends to use native commenting rather than introduce a dedicated commenting plugin.

The expected mappings are:

- `gcc` — toggle a comment on the current line.
- `gc` — toggle comments for an operator motion or Visual-mode selection.

The exact behavior depends on the active filetype, its comment configuration, and any project-defined mappings.

### 3.1 Inspect the configuration

Open `lua/config/keymaps.lua` and inspect the commenting-related implementation.

Check for custom mappings that might override or interfere with native behavior. Do not assume that a mapping is correct merely because its description looks appropriate.

In a Lua buffer, inspect the filetype and comment string:

```vim
:set filetype?
:set commentstring?
```

For Lua, the expected comment string is:

```text
-- %s
```

Record the actual values if they differ.

### 3.2 Compare clean and configured sessions

Use the same kind of test in both environments.

First, start a clean session:

```powershell
nvim --clean
```

Open a Lua file or create a disposable Lua buffer. Test `gcc` and `gc`.

Next, test the project configuration:

```powershell
nvim -u init.lua
```

Repeat the same operations with equivalent content and filetype.

A difference between the two sessions is evidence of a configuration-dependent issue. It is not, by itself, proof of which module or mapping caused the issue.

### 3.3 Test line commenting

1. Open a Lua file.
2. Place the cursor on a line of code.
3. Press `gcc`.
4. Confirm that the line is commented.
5. Press `gcc` again.
6. Confirm that the line is uncommented.

Repeat with a suitable filetype that uses different comment syntax, such as PowerShell.

### 3.4 Test selection commenting

1. Open a disposable buffer with several lines of code.
2. Enter Visual line mode and select multiple lines.
3. Press `gc`.
4. Confirm that the intended lines are commented.
5. Repeat the operation to verify that the selection can be uncommented.

Test line and selection commenting independently. Passing one does not establish that the other works.

### 3.5 Diagnostic findings

The following observations were recorded during the investigation:

- **Clean-session comparison:** `gcc` works in `nvim --clean`.
- **Configured-session mappings:** `gcc` and `gc` are registered as Lua callback mappings with the descriptions `Toggle comment line` and `Toggle comment`.
- **Lua comment syntax:** The configured Lua buffer reports `filetype=lua` and `commentstring=-- %s`. Neovim identifies the Lua filetype plugin as the source of the comment string.
- **Operator function:** `operatorfunc` is empty. This observation alone does not establish a fault.
- **Configured Lua-buffer test:** In a disposable Lua buffer under the project configuration, pressing `gcc` left the line unchanged.
- **Visual commenting:** An earlier Visual-mode `gc` test behaved unexpectedly. Successful selection commenting has not been established by that observation.

These findings establish a discrepancy between the clean and configured sessions. They do not identify the root cause.

Mapping metadata proves registration, not successful execution of the commenting operation.

### 3.6 Automated verification

The smoke test has reported:

```text
PASS native commenting
```

That result must be interpreted according to the actual assertions being performed. If the test checks only mapping registration, it does not verify that a line or selection is commented correctly.

The automated test should not be considered proof of functional commenting until it exercises the operation or is supplemented by reliable interactive verification.

### 3.7 Current status and follow-up

The configured-session line-comment test failed, and Visual-mode selection commenting remains unresolved. The cause has not been established.

The investigation is deferred pending further research.

Do not introduce replacement mappings or a commenting plugin merely to work around the unexplained behavior. In particular, do not create self-referential mappings that invoke the same mapping recursively.

**Status: Deferred and unresolved.**

Native commenting must not be considered functional until both line and selection behavior have been investigated and verified.

---

## 4. Stage 07 Interactive Verification

Stage 07 introduces navigation and editing plugins while retaining Neovim's native capabilities wherever appropriate.

The plugin modules are separate, and the mappings are expected to have meaningful descriptions and predictable behavior. Interactive tests validate actual use; automated smoke tests validate the parts that can be reliably inspected without manual interaction.

### 4.1 Test preparation

1. Launch Neovim with the project configuration.
2. Open a project containing files that can be searched and edited.
3. Keep several buffers open for buffer-navigation tests.
4. Use disposable buffers for operations that modify text.
5. Record any failure with the key, expected behavior, actual behavior, and visible error.

### 4.2 Flash navigation

#### Flash jump — `s`

1. Open a file containing several occurrences of a word.
2. Press `s`.
3. Select a displayed target label.
4. Confirm that the cursor moves to the intended location.

#### Flash Treesitter jump — `gs`

1. Open a Lua file containing nested functions, calls, or tables.
2. Press `gs`.
3. Select a displayed target.
4. Confirm that the cursor moves to the intended syntax node.

#### Preserved substitution — `S`

1. Search for a word using `/word`.
2. Press `S`.
3. Confirm that the existing substitution mapping opens a command with the previous search term populated.
4. Press `Esc` to cancel without changing the file.

This test also guards against a mapping collision: Flash's Treesitter jump uses `gs` so the existing Normal-mode `S` mapping remains intact.

#### Flash remote operation — `r`

1. In Normal mode, start an operator such as `y`.
2. Press `r`.
3. Confirm that Flash's remote-operation interface appears.
4. Select a target and inspect the result, or cancel if you do not want to modify text.

#### Flash Treesitter search — `R`

1. Enter Visual mode and select a small syntax fragment.
2. Press `R`.
3. Confirm that Flash's Treesitter search interface appears.
4. Select a matching target or cancel the operation.

#### Flash command-line toggle — `Ctrl+s`

1. Enter `/` to open the search command line.
2. Press `Ctrl+s`.
3. Confirm that Flash's search-label behavior toggles.
4. Press `Esc` to leave the command line.

This is a command-line mapping. It is distinct from the save mapping used in Normal, Insert, or Visual mode.

### 4.3 Snacks navigation

#### Find files — `<leader>ff`

1. Press Space, then `ff`.
2. Confirm that the Snacks file picker opens.
3. Search for a known repository file.
4. Select it and confirm that the file opens.

#### Search file contents — `<leader>fg`

1. Press Space, then `fg`.
2. Search for a known string in a project file.
3. Confirm that matching results appear.
4. Open a result and verify that the expected file and location are selected.

#### Find buffers — `<leader>fb`

1. Open at least two files.
2. Press Space, then `fb`.
3. Select another buffer.
4. Confirm that it becomes active.

#### File explorer — `<leader>fe`

1. Press Space, then `fe`.
2. Confirm that the Snacks file explorer opens.
3. Navigate through directories.
4. Open a selected file and verify that it becomes the active buffer.

### 4.4 fzf-lua navigation

#### Find files — `<leader>pf`

1. Press Space, then `pf`.
2. Confirm that the fzf-lua file picker opens.
3. Search for a known file and open it.

#### Search file contents — `<leader>pg`

1. Press Space, then `pg`.
2. Search for a known string.
3. Open a result and verify its location.

#### Find buffers — `<leader>pb`

1. Open multiple buffers.
2. Press Space, then `pb`.
3. Select another buffer.
4. Confirm that the selected buffer becomes active.

#### Resume picker — `<leader>pr`

1. Run an fzf-lua picker.
2. Close it after confirming that it produced results.
3. Press Space, then `pr`.
4. Confirm that the previous picker resumes when the current picker state supports resumption.

### 4.5 Editing plugins

#### mini.ai

1. Open a Lua file.
2. Place the cursor inside a function call or bracketed expression.
3. Test a suitable inside or around text object, such as `vii` or `vai`, where the syntax supports it.
4. Confirm that the intended text is selected.

#### mini.surround

Use a disposable buffer.

1. Select a word or place the cursor on suitable text.
2. Use `sa` to add a surrounding pair.
3. Use `sd` to delete a surrounding pair.
4. Use `sr` to replace a surrounding pair.
5. Verify the prompts and resulting text after each operation.

#### mini.move

Use a disposable buffer with multiple lines.

1. Press `Alt+j` and `Alt+k` in Normal mode to move a line.
2. Select multiple lines in Visual mode.
3. Test `Alt+j` and `Alt+k` again.
4. Confirm that the intended lines move and indentation remains correct.

If an Alt combination fails, determine whether the terminal or GUI intercepted the key before changing the mapping.

#### dial.nvim

1. Place the cursor on a number, date, or boolean.
2. Press `Ctrl+a` to increment.
3. Press `Ctrl+x` to decrement.
4. Select a suitable range in Visual mode.
5. Test the selection increment and decrement mappings.
6. Confirm that only the intended value or values change.

### 4.6 Keymap discovery and regression checks

#### which-key

1. Press Space.
2. Pause briefly.
3. Confirm that the leader-key menu appears.
4. Check that the expected groups and mapping descriptions are visible.

#### Existing mapping regression tests

Test existing project mappings, including:

- Save mappings.
- Window-focus mappings.
- Split-management mappings.
- The previous-search substitution mapping.
- Other important mappings that overlap with new plugin key choices.

Confirm that Stage 07 did not unintentionally replace an existing workflow.

### 4.7 Recorded Stage 07 results

The following interactive checks were reported as passed:

| Test group | Verified items | Result |
|---|---|---|
| Flash navigation | `s`, `gs`, `S`, `r`, `R`, `Ctrl+s` | Passed |
| Snacks navigation | `<leader>ff`, `<leader>fg`, `<leader>fb`, `<leader>fe` | Passed |
| fzf-lua navigation | `<leader>pf`, `<leader>pg`, `<leader>pb`, `<leader>pr` | Passed |
| Editing plugins | mini.ai, mini.surround, mini.move, dial.nvim | Passed |
| Keymap discovery | which-key and mapping regression checks | Passed |

These results reflect the reported interactive checklist. Keep the detailed test procedure available for future regressions, plugin updates, or configuration changes.

### 4.8 Automated validation recorded for Stage 07

The following checks passed on Neovim 0.12.6:

- StyLua formatting, including `stylua --check .`.
- Syntax validation for all 16 Lua files.
- Stage 06 plugin loading.
- Stage 07 registration checks for Snacks, fzf-lua, Flash, mini.ai, mini.surround, mini.move, and dial.nvim.
- Native grep and quickfix.
- Module failure contract.
- Full smoke test.

These automated results complement, but do not replace, the interactive tests.

**Status: Interactive checklist passed; automated validation passed.** Stage closure should also include the final diff review and documentation updates.

---

## 5. Recording Results

Maintain a clear distinction between the test's automated result and its interactive result.

| Workflow | Automated verification | Interactive result |
|---|---|---|
| Terminal escape (`Esc Esc`) | Mapping registration and properties checked | **Passed** — returned to Normal mode and preserved the terminal buffer |
| Native line commenting (`gcc`) | Smoke test reports `PASS native commenting`; the exact assertion scope must be considered | **Failed in configured session** — worked in `nvim --clean`, but left a configured Lua line unchanged |
| Native selection commenting (`gc`) | Smoke test reports `PASS native commenting`; functional behavior is not established by registration alone | **Unresolved** — earlier Visual-mode behavior was unexpected |
| Flash navigation | Mapping and plugin registration checks passed | **Passed** — all six listed checks reported complete |
| Snacks navigation | Mapping and plugin registration checks passed | **Passed** — all four listed checks reported complete |
| fzf-lua navigation | Mapping and plugin registration checks passed | **Passed** — all four listed checks reported complete |
| Editing plugins | Plugin and mapping checks passed | **Passed** — mini.ai, mini.surround, mini.move, and dial.nvim reported complete |
| which-key and regressions | Registration checks passed | **Passed** — keymap discovery and mapping regression checks reported complete |

Update this table whenever new evidence is collected. If a workflow fails, retain the failure or unresolved status until a correction has been tested.

---

## 6. Validation Policy

1. Verify behavior in a real Neovim session before changing the implementation.
2. Separate syntax validation, automated assertions, and interactive behavior.
3. Record every interactive test as passed, failed, unverified, or deferred.
4. Reproduce failures before modifying the configuration.
5. Investigate root causes rather than hiding symptoms.
6. Preserve existing mappings unless a deliberate design decision changes them.
7. Add automated regression tests for stable, testable behavior where practical.
8. Do not introduce a plugin solely to avoid investigating a native workflow.
9. Keep unresolved behavior documented with concrete evidence and next steps.
10. Re-run relevant validation after a change.
11. Do not declare a stage complete until its acceptance criteria have been satisfied.
12. Do not treat a successful smoke test as proof of behavior that the test does not exercise.

## 7. Outstanding Follow-ups

### Native commenting

1. Resume the investigation after further research.
2. Determine why `gcc` works in `nvim --clean` but has no visible effect in a configured Lua buffer.
3. Verify Visual-mode selection commenting (`gc`) independently.
4. Inspect the configured mappings and callback behavior to determine the root cause.
5. After any correction, repeat the clean-versus-configured comparison and test multiple filetypes.
6. Update this document only after the observed results support the revised status.

### Stage 07 closeout

1. Review the final repository diff.
2. Confirm that the navigation and editing modules match the documented behavior.
3. Update the project roadmap and supporting documentation to reflect the completed checks.
4. Run formatting, syntax, smoke, and whitespace checks after documentation or code changes.
5. Commit only after the final review and validation are complete.

### Stage 04 status

The terminal escape workflow is verified. Native commenting remains unresolved.

**Stage 04 remains in progress until its acceptance criteria are satisfied.**

Stage 07's interactive checklist and automated checks have been reported as passing. Its final closeout should be recorded separately from Stage 04; unresolved native commenting must not be marked complete merely because later-stage tests pass.

---

## 8. Quick Validation Reference

Run these commands from the repository root in PowerShell:

```powershell
# Format the Lua files.
stylua .

# Verify formatting.
stylua --check .

# Validate Lua syntax.
nvim --headless -u NONE -l scripts/check-syntax.lua

# Run the configuration smoke test.
nvim --headless -u init.lua -c "luafile scripts/smoke.lua"

# Check the diff for whitespace errors.
git diff --check

# Review modified and untracked files.
git status --short
```

After automated validation, run the interactive procedures relevant to the changed modules.

The guiding rule is simple: **verify the implementation at the level of behavior the project promises, document the evidence, and leave unresolved work explicitly unresolved.**
