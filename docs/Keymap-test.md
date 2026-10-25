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
- Syntax validation for all 16 Lua files at the time of that validation.
- Stage 06 plugin loading.
- Stage 07 registration checks for Snacks, fzf-lua, Flash, mini.ai, mini.surround, mini.move, and dial.nvim.
- Native grep and quickfix.
- Module failure contract.
- Full smoke test.

These automated results complement, but do not replace, the interactive tests.

**Status: Interactive checklist passed; automated validation passed.** Stage closure should also include the final diff review and documentation updates.

---

## 5. Stage 09 — LSP Interactive Verification

Stage 09 integrates Neovim's native Language Server Protocol (LSP) client with LuaLS. The `nvim-lspconfig` plugin supplies maintained server definitions, while Neovim's native LSP APIs configure and activate the server. The `lazydev.nvim` plugin improves LuaLS awareness of Neovim and installed Lua libraries; it does not install or manage the language-server executable.

This section verifies actual server attachment and LSP behavior, not just the existence of configuration entries or mappings.

### 5.1 Test prerequisites

Before testing, confirm the following:

- The `lua-language-server` executable is installed and available on `PATH`.
- The project configuration loads successfully.
- The `nvim-lspconfig` and `lazydev.nvim` plugins are installed and loaded.
- The Lua language pack and native LSP configuration are loaded.
- The test file is recognized as a Lua buffer.
- The buffer is in a workspace where LuaLS can determine an appropriate root.

Check the executable from PowerShell:

```powershell
Get-Command lua-language-server
```

If PowerShell cannot find the executable, resolve the external installation or `PATH` configuration before investigating Neovim's LSP setup. LuaLS is managed externally through the chosen system package manager, `mise`, or another explicitly selected tool manager. Mason is not part of the default configuration.

### 5.2 Confirm LuaLS attachment

1. Start Neovim with the project configuration:

   ```powershell
   nvim -u init.lua
   ```

2. Open a Lua file inside the intended workspace.
3. Check the buffer's filetype:

   ```vim
   :set filetype?
   ```

   The expected value is `lua`.

4. Inspect active LSP clients:

   ```vim
   :checkhealth vim.lsp
   ```

   Also inspect the attached clients for the current buffer using the LSP client information available in the installed Neovim version.

5. Confirm that `lua_ls` is attached to the Lua buffer.

6. If it is not attached, inspect the executable, server startup errors, workspace/root detection, and Neovim messages before changing the configuration.

**Expected result:** LuaLS attaches to the Lua buffer when the executable is available, the server configuration is valid, and the workspace requirements are satisfied.

Registering `vim.lsp.config.lua_ls` or enabling `lua_ls` is not sufficient evidence of attachment. Record the actual attachment result separately.

### 5.3 Verify buffer-local mappings

The configuration registers the LSP mappings from the `LspAttach` event. They should be buffer-local and should only be installed for a buffer when an LSP client attaches.

1. Open a Lua buffer where LuaLS successfully attaches.
2. Inspect the mappings:

   ```vim
   :verbose nmap gd
   :verbose nmap gD
   ```

3. Confirm that the mappings are available in the attached buffer and that their descriptions identify the LSP actions.
4. Switch to a buffer with no attached LSP client.
5. Inspect the same mappings there.
6. Confirm that the LSP-specific mappings have not been added to that buffer merely because the configuration started.

Use `:verbose nmap` to help identify the mapping definition and its source. When testing multiple buffers, verify the current buffer before drawing conclusions.

**Expected result:** `gd` and `gD` are buffer-local mappings registered on LSP attachment. A non-LSP buffer does not receive these mappings simply from configuration startup.

### 5.4 Test definition navigation — `gd`

1. Open a Lua file with a function or variable whose definition can be resolved by LuaLS.
2. Place the cursor on a reference to that symbol.
3. Press `gd`.
4. Confirm that the cursor navigates to the symbol's definition.
5. Return to the original location and repeat with another resolvable symbol.

**Expected result:** `gd` invokes the LSP definition action and navigates to a definition when LuaLS can resolve one.

A missing definition result does not automatically prove that the mapping is broken. Check that the symbol is resolvable and that the server is attached and responding.

### 5.5 Test declaration navigation — `gD`

1. Open a Lua file containing a symbol with a declaration that LuaLS can resolve.
2. Place the cursor on a reference to that symbol.
3. Press `gD`.
4. Confirm that Neovim navigates to the declaration when the server provides one.

**Expected result:** `gD` invokes the LSP declaration action. Successful navigation depends on the server supporting and returning a declaration location for the tested symbol.

Do not require `gD` to produce a different location from `gd` for every symbol. Some language-server responses may identify the same location, and some symbols may not have a separately resolvable declaration.

### 5.6 Test hover information

1. Open a Lua file with a resolvable function, variable, or library symbol.
2. Place the cursor over the symbol.
3. Invoke Neovim's native LSP hover action using the configured or built-in hover command/key sequence.
4. Confirm that a hover window or equivalent information display appears when LuaLS returns documentation or type information.
5. Repeat with a symbol from the Neovim API to check that the Lua development environment provides useful information where applicable.

**Expected result:** Hover displays information returned by LuaLS for supported symbols. Missing documentation for an individual symbol is not, by itself, proof of a broken hover workflow.

### 5.7 Test diagnostics

1. Open a disposable Lua file.
2. Introduce a clear syntax error and save or otherwise trigger an update.
3. Confirm that LuaLS reports a relevant diagnostic when the file is analyzed.
4. Correct the syntax error and confirm that the diagnostic clears after the server updates.
5. Test a Lua-specific diagnostic, such as referencing an undefined global, and confirm that the result matches the configured diagnostics policy.
6. Check Neovim's diagnostic display and message area for errors that might indicate server startup or communication failures.

The project configures `vim` as a recognized global for Lua diagnostics, disables third-party workspace prompts, and disables LuaLS telemetry. The `vim` global should therefore not be reported as undefined solely because it is a Neovim API global.

**Expected result:** LuaLS publishes diagnostics for relevant issues, and diagnostics update when the underlying issue is corrected. The exact diagnostics depend on the server's analysis and the contents of the test file.

### 5.8 Verify non-LSP buffer isolation

This regression check ensures that the LSP mappings are registered by attachment rather than globally at startup.

1. Start Neovim with the project configuration.
2. Open a plain text buffer or another buffer that has no attached LSP client.
3. Inspect `gd` and `gD` in that buffer:

   ```vim
   :verbose nmap gd
   :verbose nmap gD
   ```

4. Confirm that the LSP-specific buffer-local mappings are absent.
5. Open a Lua buffer where LuaLS attaches.
6. Confirm that the LSP mappings become available in that buffer.
7. Switch back to the non-LSP buffer and repeat the check.

**Expected result:** The LSP-specific mappings appear in the buffer where the attachment event registers them, and they do not leak into unrelated buffers.

A global mapping with the same key can still exist independently. The test must distinguish an unrelated global mapping from the configuration's LSP-specific buffer-local mappings.

### 5.9 Automated verification

Automated checks should cover the stable configuration contract where practical:

- The project-local language-pack registry discovers the intended Lua pack.
- The Lua pack declares `lua_ls` as a supported server.
- The effective `vim.lsp.config.lua_ls` contains the expected Lua settings.
- The server configuration has the expected command and filetype, using defaults from `nvim-lspconfig` where appropriate.
- LSP mappings are installed as buffer-local mappings from the attachment callback.
- Repeated setup does not create duplicate autocmds or duplicate setup effects.
- The Stage 09 configuration does not assume that Python language-server support has already been implemented.

Run the standard checks:

```powershell
stylua --check .
nvim --headless -u NONE -l scripts/check-syntax.lua
nvim --headless -u init.lua -c "luafile scripts/smoke.lua"
git diff --check
```

These checks do not replace interactive confirmation that LuaLS starts, attaches to the intended buffer, responds to requests, and publishes diagnostics. A registered configuration entry is not proof of a running or attached server.

### 5.10 Recorded result

The following results have been reported from interactive testing:

- LuaLS attached to a Lua buffer.
- Definition navigation using `gd` worked.
- Hover information worked.
- Declaration navigation using `gD` did not work in the tested case.

The declaration result does not establish a general failure if the tested symbol or server response did not support a separate declaration location. Diagnostics and non-LSP buffer isolation still require their own recorded evidence.

| Test | Expected evidence | Result |
|---|---|---|
| LuaLS availability | Executable resolves on `PATH` | Unverified until confirmed |
| LuaLS attachment | `lua_ls` is attached to the intended Lua buffer | Passed — attachment was observed |
| `gd` definition | Cursor navigates to a resolvable definition | Passed — definition navigation was observed |
| `gD` declaration | Cursor navigates to a declaration when supported | Not supported in the tested case; investigate with a suitable symbol |
| Hover | Server-provided hover information appears | Passed — hover was observed |
| Diagnostics | Relevant diagnostics appear and update | Unverified until tested |
| Buffer-local mappings | LSP mappings are registered on attachment | Automated configuration checks passed; interactive isolation requires confirmation |
| Non-LSP buffer isolation | LSP-specific mappings are absent from unrelated buffers | Unverified until tested |

Replace each result only after collecting evidence. If a server feature is unsupported for a particular symbol, record that limitation and test with a suitable symbol before marking the workflow failed.

**Status: Partially verified. Attachment, definition navigation, and hover were observed; declaration behavior, diagnostics, and buffer isolation need further verification.**

---

## 6. Stage 10 — Completion, Snippets, and Automatic Pairing

Stage 10 introduces Blink completion, the `friendly-snippets` collection, Neovim's native snippet API, and automatic bracket and quote pairing through `mini.pairs`.

The implementation follows the project's native-first policy:

- Blink provides completion and its completion interface.
- `friendly-snippets` provides a collection of snippets.
- Neovim's native `vim.snippet` API handles snippet expansion and navigation.
- `mini.pairs` provides automatic pairing, using the existing `mini.nvim` installation.
- Plugins are loaded eagerly; lazy-loading is not introduced before Stage 16.
- Language servers remain configured through Neovim's native LSP APIs.

Automated smoke tests verify the configuration contract and the availability of expected APIs. Interactive tests must establish that completion, snippet expansion, and pairing work in an actual editing session.

### 6.1 Test prerequisites

Before testing, confirm that:

- Neovim 0.12 or later is running.
- The project configuration loads without errors.
- `blink.cmp` and `friendly-snippets` are installed and loaded.
- The existing `mini.nvim` installation provides `mini.pairs`.
- A Lua or other supported source buffer is available for testing.
- A disposable buffer is used for tests that change text.

Launch Neovim:

```powershell
nvim -u init.lua
```

Use the project configuration rather than `nvim --clean` for the primary test. A clean session does not load the project's completion and pairing configuration.

### 6.2 Verify Blink completion

1. Open a source file with a supported filetype.
2. Enter a partial identifier or expression that can produce completion candidates.
3. Confirm that the completion menu appears when candidates are available.
4. Inspect the displayed candidates and verify that they are relevant to the text being entered.
5. Use Blink's configured default keymap to navigate the candidates.
6. Accept a candidate.
7. Confirm that the expected text is inserted and that the surrounding buffer content remains correct.
8. Repeat with an identifier that can be supplied by the attached language server, if available.
9. Repeat with a filesystem path or a word already present in the buffer to exercise the other configured completion sources where applicable.

The configured completion sources are:

- LSP
- Filesystem paths
- Snippets
- Words from the current buffer

Not every source must produce candidates in every context. Test each source with a suitable input before recording its behavior.

**Expected result:** Blink displays relevant candidates when a configured source supplies them, allows candidate selection, and inserts the accepted completion correctly.

A loaded completion module or visible menu alone does not establish that accepting a candidate works.

### 6.3 Verify snippet completion and expansion

1. Open a suitable source buffer.
2. Enter a prefix associated with a snippet supported by `friendly-snippets`.
3. Confirm that a snippet candidate appears when the current completion context and source provide one.
4. Select and accept the snippet candidate.
5. Confirm that the snippet expands into the expected text.
6. If the snippet contains placeholders or tab stops, test navigation through them using Neovim's native snippet workflow.
7. Confirm that snippet navigation behaves as expected and that exiting the snippet does not leave the editor in an unexpected state.

Use a known snippet for the selected filetype. If no candidate appears, check the filetype, prefix, completion context, and available snippet definitions before concluding that the integration is broken.

Neovim's native snippet API is responsible for expansion and navigation. Do not assume that `friendly-snippets` itself implements those editing operations.

**Expected result:** A suitable snippet can be discovered through completion, accepted, expanded, and navigated using the configured native snippet workflow.

### 6.4 Verify automatic bracket and quote pairing

Use a disposable buffer to avoid modifying project files unintentionally.

1. Enter Insert mode.
2. Type an opening parenthesis, `(`.
3. Confirm that the matching closing parenthesis is inserted as expected.
4. Repeat with square brackets, curly braces, and a suitable quote character.
5. Type content between a pair and confirm that the cursor behaves as expected.
6. Test the closing-character behavior to ensure that typing an existing closing delimiter does not produce unintended duplicate text.
7. Test backspace behavior inside an automatically inserted pair.
8. Repeat the relevant checks in another suitable filetype.

The exact behavior can depend on the character, editing context, and `mini.pairs` configuration. Record unexpected behavior rather than assuming every delimiter must behave identically.

**Expected result:** Common opening delimiters and quotes are paired appropriately, and subsequent editing behaves consistently with the configured `mini.pairs` behavior.

### 6.5 Verify interaction with existing mappings

1. Confirm that existing save mappings still work.
2. Confirm that existing window-focus and split-management mappings remain available.
3. Confirm that Stage 07 navigation mappings remain functional.
4. Verify that LSP mappings remain buffer-local and that completion does not prevent their intended use.
5. Check any completion-key conflict by inspecting the actual mapping and testing the affected workflow.
6. Confirm that automatic pairing does not interfere with ordinary insertion, deletion, or editing in a disposable buffer.

Do not assume that adding a completion engine necessarily creates a conflict. Establish the actual mapping and behavior before changing either implementation.

### 6.6 Automated verification

Run the standard project checks:

```powershell
stylua --check .
nvim --headless -u NONE -l scripts/check-syntax.lua
nvim --headless -u init.lua -c "luafile scripts/smoke.lua"
git diff --check
```

The Stage 10 smoke test checks the following configuration properties:

- The Blink, `friendly-snippets`, and `mini.pairs` modules have loaded.
- The Blink completion module exposes the expected public APIs.
- Neovim's native snippet API exposes the expected expansion and navigation functions.
- `friendly-snippets` is registered as an active installed plugin.
- `mini.pairs` is loaded and its setup API is available.
- Representative automatic-pair mappings are registered.

These assertions verify the tested configuration contract. They do not prove that completion candidates are relevant, that accepting a candidate inserts the correct text, that a particular snippet expands correctly, or that pairing behaves correctly in every editing context.

### 6.7 Recorded automated result

The reported smoke-test output includes:

```text
PASS Stage 10 completion, snippets, and pairing
PASS nvim-config smoke test on Neovim 0.12.6
```

The following checks were also reported as passing:

- `stylua --check .`
- `git diff --check`
- The complete configured smoke test, including the earlier stage checks.

These results establish that the recorded automated assertions passed on Neovim 0.12.6. Record interactive behavior separately.

### 6.8 Interactive result record

| Test | Evidence required | Result |
|---|---|---|
| Blink candidate display | Relevant candidates appear in a suitable completion context | Passed — completion candidates were observed |
| Candidate navigation | Selection moves between candidates as expected | Passed — candidate navigation was observed |
| Candidate acceptance | Accepted text is inserted correctly | Passed — acceptance was observed |
| Snippet discovery | A known snippet is offered for the appropriate context | Unverified until recorded |
| Snippet expansion | Accepted snippet expands correctly | Unverified until recorded |
| Snippet navigation | Placeholders and tab stops work where provided | Unverified until recorded |
| Automatic pairing | Opening delimiters and quotes produce expected pairs | Unverified until recorded |
| Pair editing behavior | Closing delimiters and backspace behave as expected | Unverified until recorded |
| Existing mappings | Important earlier workflows remain functional | Unverified until recorded |

Replace a result only after testing the corresponding behavior. If a test is not applicable to the chosen filetype or snippet, record the reason rather than marking it passed.

**Status: Automated validation passed; Blink completion was interactively observed working. Snippet and complete pairing behavior require explicit recorded results.**

---

## 7. Recording Results

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
| Stage 09 LSP | Configuration and mapping contract checked by automated tests | **Partially verified** — LuaLS attachment, definition navigation, and hover were observed; declaration navigation was not supported in the tested case. Diagnostics and non-LSP buffer isolation require separate recorded results |
| Stage 10 completion | Module loading, public APIs, snippet registration, and representative pairing mappings checked | **Partially verified** — Blink completion was observed working, including candidate navigation and acceptance. Snippet expansion/navigation and the complete automatic-pairing workflow still require explicit recorded results |

Update this table whenever new evidence is collected. If a workflow fails, retain the failure or unresolved status until a correction has been tested.

---

## 8. Validation Policy

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

---

## 9. Outstanding Follow-ups

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

### Stage 09 LSP verification

1. Retain the reported evidence that LuaLS attached to a Lua buffer and that definition navigation and hover worked.
2. Investigate declaration navigation with a suitable symbol and record whether the server supports the requested declaration result.
3. Verify diagnostics and confirm that they update when an issue is corrected.
4. Confirm that LSP-specific mappings remain buffer-local and do not leak into unrelated buffers.
5. Keep automated configuration checks separate from interactive server-behavior results.

### Stage 10 completion, snippets, and pairing

1. Retain the passing automated smoke-test result for completion, snippets, and pairing.
2. Verify Blink candidate display, navigation, and acceptance in an interactive session.
3. Verify a known `friendly-snippets` entry, including expansion and placeholder navigation when supported.
4. Test `mini.pairs` with common delimiters and quotes, including closing-character and backspace behavior.
5. Check that important existing mappings continue to work.
6. Update the interactive results table only after collecting evidence for each workflow.
7. Do not treat the Stage 10 smoke-test result as proof that every interactive workflow passed.

### Stage 04 status

The terminal escape workflow is verified. Native commenting remains unresolved.

**Stage 04 remains in progress until its acceptance criteria are satisfied.**

Stage 07's interactive checklist and automated checks have been reported as passing. Its final closeout should be recorded separately from Stage 04; unresolved native commenting must not be marked complete merely because later-stage tests pass.

---

## 10. Quick Validation Reference

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
