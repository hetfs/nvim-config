# Lua Language Support

- **Status:** In progress — core LuaLS, StyLua, standalone-project, and Tree-sitter workflows validated
- **Last validated:** 2026-10-27
- **Roadmap stage:** Stage 13 — Language Packs
- **Validated environment:** Windows, Neovim 0.12.6

## 1. Purpose and scope

Define the implementation, dependencies, workflow, and validation requirements for Lua language support in `nvim-config`.

Lua is both a supported programming language and the implementation language of the Neovim configuration itself. Support must cover ordinary Lua development and Neovim-specific APIs without indiscriminately applying Neovim-specific assumptions to every Lua project.

The project follows this principle:

> **Minimum installation. Compose the rest.**

This document distinguishes the current implementation, completed tests, and outstanding validation. A test is considered passed only when its result has been observed and recorded.

## 2. Architecture and decisions

Lua support uses the existing language-pack architecture, native Neovim LSP APIs, shared formatting infrastructure, and Tree-sitter integration.

| Capability | Component | Responsibility |
|---|---|---|
| Language intelligence | LuaLS (`lua_ls`) | Diagnostics, completion, hover, and code navigation |
| Server definitions | `nvim-lspconfig` | Maintained LuaLS server definition |
| Neovim API context | lazydev.nvim | Lua development context for Neovim APIs and libraries |
| Formatting | StyLua (`stylua`) | Consistent Lua formatting |
| Formatter integration | Conform.nvim | Formatter resolution and execution |
| Syntax parsing and highlighting | Existing Tree-sitter integration | Lua parsing and highlighting |
| Language-pack registration | `lua/langs/init.lua` | Pack discovery, setup, and formatter metadata collection |

The implementation must:

- Use Neovim's native `vim.lsp.config()` and `vim.lsp.enable()` APIs.
- Keep Lua-specific configuration in `lua/langs/lua.lua`.
- Reuse the existing language registry and formatter contract.
- Keep user-facing keymaps centralized in `lua/config/keymaps.lua`.
- Install external executables separately from Neovim plugins.
- Avoid Mason and other automatic tool installers.
- Avoid a separate Lua linter unless a demonstrated requirement justifies one.
- Keep formatting manual; format-on-save remains disabled.
- Avoid duplicate LSP, formatter, parser, and project-root infrastructure.

LuaLS, StyLua, and Tree-sitter have distinct responsibilities. None replaces the others.

## 3. Language server: LuaLS

LuaLS provides diagnostics, completion, hover, definition navigation, and other language-server capabilities. The `nvim-lspconfig` plugin supplies the maintained `lua_ls` definition but does not install the LuaLS executable.

The existing configuration in `lua/langs/lua.lua` uses Neovim's native LSP APIs and configures these LuaLS settings:

| Setting | Current value | Purpose |
|---|---|---|
| `Lua.runtime.version` | `LuaJIT` | Matches Neovim's Lua runtime |
| `Lua.diagnostics.globals` | `{ "vim" }` | Recognizes Neovim's `vim` global |
| `Lua.workspace.checkThirdParty` | `false` | Disables third-party workspace checks |
| `Lua.telemetry.enable` | `false` | Disables LuaLS telemetry |

The effective configuration also showed `codeLens` and `hint` settings. Their presence in the effective configuration does not prove that the project explicitly declares them.

Do not describe a workspace library setting or explicit `vim.env.VIMRUNTIME` configuration as implemented unless the repository configuration confirms it.

### Workspace isolation

LuaLS must use the correct workspace for each project.

- The `nvim-config` repository targets Neovim's LuaJIT environment and APIs.
- Standalone Lua projects may target other Lua runtimes and must not automatically inherit Neovim-specific assumptions.
- Project-specific `.luarc.json` settings must be respected.

The standalone-project and project-specific diagnostic tests have passed. The Lua 5.4 runtime override has not been independently verified.

### lazydev.nvim

lazydev.nvim improves LuaLS awareness of Neovim APIs and installed Lua libraries during Neovim configuration and plugin development.

It does not install or manage the LuaLS executable. Validate plugin setup, executable availability, server activation, and LSP attachment independently.

## 4. Formatting: StyLua and Conform

StyLua is the default Lua formatter and is integrated through the shared Conform workflow.

The Lua language pack declares formatter metadata using the existing contract:

```lua
local M = {
  formatters = {
    lua = { "stylua" },
  },
}
```

This is an excerpt of the metadata declaration, not a replacement for the complete language-pack module.

The workflow is:

1. `lua/langs/lua.lua` declares StyLua as the Lua formatter.
2. `lua/langs/init.lua` collects formatter metadata.
3. `lua/config/format.lua` resolves the configured formatter.
4. Conform invokes StyLua through the existing `:Format` command.

The validated formatting policy is:

- Use the repository's existing StyLua configuration.
- Use `:Format` for manual formatting.
- Keep `lsp_format = "never"` in the shared Conform options.
- Do not enable format-on-save.
- Report unavailable formatters without installing them automatically.
- Keep formatter selection centralized in the existing language and formatting modules.

StyLua version `2.6.0` was observed in the development environment. The repository-wide formatting check and manual `:Format` workflow passed.

## 5. Diagnostics, Tree-sitter, and linting

### Diagnostics and linting

LuaLS provides language diagnostics, including undefined-global checks. Keep useful diagnostics enabled.

A separate Lua linter is not part of the initial implementation. Consider one only when a concrete diagnostic gap has been demonstrated and its benefits justify the added dependency, configuration, diagnostic lifecycle, and maintenance costs.

### Tree-sitter

Lua uses the existing Tree-sitter integration. No separate parser manager or duplicate integration should be introduced.

Validation has confirmed the Lua filetype, language mapping, parser retrieval, active highlighter, and visible syntax highlighting.

Tree-sitter handles parsing and highlighting; it does not replace LuaLS diagnostics or StyLua formatting.

## 6. Module responsibilities and dependencies

### Relevant modules

| Path | Responsibility |
|---|---|
| `lua/langs/lua.lua` | LuaLS configuration and Lua formatter metadata |
| `lua/langs/init.lua` | Language-pack discovery, setup, and metadata collection |
| `lua/config/lsp.lua` | Shared LSP behavior and lifecycle |
| `lua/config/languages.lua` | Language and formatter preferences |
| `lua/config/format.lua` | Conform integration and formatter resolution |
| `lua/plugins/lsp.lua` | LSP-related plugin declarations |
| `lua/plugins/lazydev.lua` | lazydev setup |
| `lua/plugins/conform.lua` | Conform plugin declaration |
| `lua/plugins/treesitter.lua` | Existing Tree-sitter integration |
| `lua/config/keymaps.lua` | Centralized user-facing keymaps |

Preserve existing module interfaces. Do not create duplicate modules or rebuild working shared infrastructure merely to match the documentation.

### Dependencies

| Dependency | Type | Installation policy |
|---|---|---|
| `lua-language-server` | External executable | Installed separately and available on `PATH` |
| `stylua` | External executable | Installed separately and available on `PATH` |
| `nvim-lspconfig` | Neovim plugin | Managed by the existing `vim.pack` workflow |
| `lazydev.nvim` | Neovim plugin | Managed by the existing `vim.pack` workflow |
| Conform.nvim | Neovim plugin | Managed by the existing `vim.pack` workflow |
| Tree-sitter integration and Lua parser | Plugin and parser | Managed by the existing integration |

Recorded development-environment versions:

- Neovim `0.12.6`
- LuaLS `3.19.2`
- StyLua `2.6.0`

These are observed versions, not minimum supported versions.

Installation and executable verification instructions belong in `docs/dependencies.md`. Neovim startup must not install, update, or provision external tools.

## 7. Validation procedures and results

Validation distinguishes automated checks from interactive behavior. Passing automated checks does not, by itself, prove that every workspace scenario or failure path works.

### 7.1 Automated repository checks

Run from the `nvim-config` repository root in PowerShell:

```powershell
Set-Location "$HOME\Desktop\nvim-config"

stylua --check .

nvim --headless -u NONE -l scripts/check-syntax.lua

nvim --headless -u init.lua -c "luafile scripts/smoke.lua"

git diff --check
```

Expected results:

| Command | Expected result | Recorded result |
|---|---|---|
| `stylua --check .` | No formatting violations | PASS |
| `nvim --headless -u NONE -l scripts/check-syntax.lua` | All Lua files pass syntax validation | PASS — 31 files |
| `nvim --headless -u init.lua -c "luafile scripts/smoke.lua"` | Configuration smoke checks pass | PASS |
| `git diff --check` | No whitespace errors | PASS |

The smoke test passed on Neovim `0.12.6`. Reported coverage includes plugin registration, language-pack and LSP configuration, completion and snippets, formatting and linting configuration, Git/project/session registration, native grep and quickfix, native commenting, and the module-failure contract.

Record command exit statuses when repeating the tests. Do not infer that an external executable works merely because a configuration smoke test passes.

### 7.2 Executable and version checks

Run:

```powershell
Get-Command nvim -ErrorAction SilentlyContinue
Get-Command lua-language-server -ErrorAction SilentlyContinue
Get-Command stylua -ErrorAction SilentlyContinue
Get-Command git -ErrorAction SilentlyContinue
```

Inspect versions:

```powershell
nvim --version
lua-language-server --version
stylua --version
git --version
```

These commands establish executable discovery and report versions. They do not prove correct LSP attachment or successful formatting inside Neovim.

### 7.3 LuaLS attachment and configuration

Open a Lua file in Neovim.

Check the filetype:

```vim
:set filetype?
```

Expected: `filetype=lua`.

Inspect attached LSP clients:

```vim
:lua vim.print(vim.lsp.get_clients({ bufnr = 0 }))
```

Inspect the LuaLS workspace root:

```vim
:lua for _, c in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do if c.name == "lua_ls" then vim.print(c.root_dir) end end
```

Inspect the configured server:

```vim
:lua vim.print(vim.lsp.config.lua_ls)
```

Expected results:

- LuaLS attaches to the Lua buffer.
- The workspace root matches the intended project.
- The effective configuration contains the expected Neovim-specific settings for `nvim-config`.

**Recorded result: PASS.** LuaLS attachment, filetype, repository root, effective settings, diagnostics, hover, completion, definition navigation, and recognition of the `vim` global were tested interactively.

`:LspInfo` is not a built-in command in this configuration; use the native LSP APIs above instead of adding a plugin solely for that command.

### 7.4 Diagnostics

To test undefined-global diagnostics, temporarily add an intentional error:

```lua
print(deliberately_undefined_global)
```

Inspect the current buffer's diagnostics:

```vim
:lua vim.print(vim.diagnostic.get(0))
```

Expected: LuaLS reports the undefined global. Remove the deliberate error after testing.

**Recorded result: PASS.**

### 7.5 Completion, hover, and navigation

Use a Neovim API expression such as:

```lua
vim.api.nvim_get_current_buf()
```

Test completion and hover using the configured editor workflow. Test definition navigation and references on a locally defined symbol.

Expected: completion and hover provide relevant information, definition navigation reaches the correct declaration, and references identify relevant occurrences.

**Recorded result: PASS** for completion, hover, and definition navigation. References were also reported as passing during interactive validation.

### 7.6 StyLua and Conform

Inspect formatter configuration:

```vim
:ConformInfo
```

Expected: StyLua is available for Lua buffers and the existing Conform configuration is active.

Format a Lua buffer:

```vim
:Format
```

Expected: StyLua formats the buffer using the repository's formatting configuration.

**Recorded result: PASS.** Conform reported StyLua as ready, and actual formatting through `:Format` succeeded. The repository-wide StyLua check also passed.

### 7.7 Standalone Lua project

Create a disposable project:

```powershell
$Project = "$HOME\Desktop\lua-standalone-validation"

New-Item -ItemType Directory -Force $Project | Out-Null
Set-Location $Project

git init
```

Create `main.lua`:

```lua
local function greet(name)
  return "Hello, " .. name
end

print(greet("Lua"))

-- Neovim's `vim` API is not part of an ordinary standalone Lua runtime.
print(vim.api.nvim_get_current_buf())
```

Open the file:

```powershell
nvim main.lua
```

Verify:

```vim
:set filetype?
:lua vim.print(vim.lsp.get_clients({ bufnr = 0 }))
:lua for _, c in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do if c.name == "lua_ls" then vim.print(c.root_dir) end end
:lua vim.print(vim.diagnostic.get(0))
```

Expected:

- The filetype is Lua.
- LuaLS attaches.
- The root corresponds to the standalone project.
- Diagnostics reflect the standalone project's settings rather than silently assuming all Neovim APIs exist.

**Recorded result: PASS**, based on the completed interactive validation.

### 7.8 Project-specific `.luarc.json`

Create a disposable project:

```powershell
$Project = "$HOME\Desktop\lua-luarc-validation"

New-Item -ItemType Directory -Force $Project | Out-Null
Set-Location $Project

git init
```

Create `.luarc.json`:

```json
{
  "runtime.version": "Lua 5.4",
  "diagnostics.globals": ["project_marker"],
  "workspace.checkThirdParty": false,
  "telemetry.enable": false
}
```

Create `main.lua`:

```lua
print(project_marker)
print(unconfigured_marker)
```

Open the project:

```powershell
nvim main.lua
```

Inspect the workspace and diagnostics:

```vim
:set filetype?
:lua vim.print(vim.lsp.get_clients({ bufnr = 0 }))
:lua for _, c in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do if c.name == "lua_ls" then vim.print(c.root_dir) end end
:lua vim.print(vim.diagnostic.get(0))
```

Expected:

- LuaLS attaches to the project.
- The root corresponds to the directory containing `.luarc.json`.
- `project_marker` is recognized as a configured global.
- `unconfigured_marker` produces an undefined-global diagnostic.

**Recorded result: PASS.** The project root was reported as `lua-luarc-validation`; `project_marker` was accepted and `unconfigured_marker` was diagnosed.

**Limitation:** The project-specific diagnostic override was verified. The `Lua 5.4` runtime override was not independently confirmed and must not be recorded as passed.

### 7.9 Tree-sitter

In a Lua buffer, run:

```vim
:set filetype?
:lua vim.print(vim.treesitter.language.get_lang("lua"))
:lua vim.print(vim.treesitter.get_parser(0):lang())
:lua vim.print(vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()] ~= nil)
```

Expected:

- Filetype is `lua`.
- Language mapping is `lua`.
- Parser language is `lua`.
- The active highlighter check returns `true` when highlighting is active.

Also visually inspect the buffer for syntax highlighting.

**Recorded result: PASS**, as confirmed by the completed filetype, mapping, parser, active-highlighter, and visual-highlighting checks.

### 7.10 Missing dependencies and formatter failure

These are required failure-path tests. Use an isolated environment or temporary `PATH` that excludes the relevant executable while preserving the tools needed to run the test. Do not uninstall tools from the main development environment.

**Missing LuaLS**

Check normal executable discovery:

```powershell
Get-Command lua-language-server -ErrorAction SilentlyContinue
```

In the isolated environment, verify that a missing executable is reported, LuaLS does not falsely appear operational, no automatic installation occurs, and unrelated configuration modules still load.

**Missing StyLua**

Check normal executable discovery:

```powershell
Get-Command stylua -ErrorAction SilentlyContinue
```

In the isolated environment, run:

```vim
:ConformInfo
:Format
```

Verify that the missing formatter is reported clearly, no automatic installation occurs, and unrelated configuration remains usable.

**Formatter failure**

Use a disposable Lua file. Record its original contents, introduce invalid or unformattable input, run `:Format`, inspect the output and log, and then restore or remove the fixture.

To inspect the usual Conform log location on Windows:

```powershell
Get-Content "$env:LOCALAPPDATA\nvim-data\conform.log" -Tail 100
```

The location may differ if Neovim's data directory has been customized.

For all three failure-path tests, record the actual result before marking the test passed. These tests are **not yet verified** by the current validation record.

## 8. Consolidated test status

| Test area | Status | Notes |
|---|---|---|
| StyLua repository check | PASS | `stylua --check .` |
| Lua syntax checker | PASS | 31 Lua files |
| Headless configuration smoke test | PASS | Neovim 0.12.6 |
| Git whitespace check | PASS | `git diff --check` |
| LuaLS attachment and repository root | PASS | Interactive test |
| LuaLS diagnostics, hover, completion, and navigation | PASS | Interactive tests |
| Manual StyLua formatting through Conform | PASS | `:Format` |
| Standalone Lua workspace and diagnostics | PASS | Interactive test |
| Project-specific `.luarc.json` diagnostics | PASS | Configured and unconfigured globals distinguished |
| `.luarc.json` Lua 5.4 runtime override | NOT VERIFIED | Runtime application not independently confirmed |
| Tree-sitter mapping, parser, and highlighting | PASS | Interactive test |
| Missing LuaLS behavior | NOT VERIFIED | Controlled failure test required |
| Missing StyLua behavior | NOT VERIFIED | Controlled failure test required |
| Formatter failure feedback | NOT VERIFIED | Controlled failure test required |
| Other operating systems | NOT VERIFIED | Windows is the recorded environment |

## 9. Completion criteria

Lua support can be marked complete when:

- LuaLS uses the shared native LSP architecture.
- Neovim-specific runtime and diagnostic settings work as intended.
- Standalone Lua projects and project-specific configuration behave correctly.
- StyLua is integrated through Conform and actual formatting succeeds.
- Tree-sitter parsing and highlighting work through the existing integration.
- Missing executables are handled without automatic installation or unrelated startup failures.
- Formatter failures provide understandable feedback.
- Automated and interactive validation results are recorded.
- Dependency documentation accurately describes the supported setup.

Core LuaLS, StyLua, standalone-project, project-specific diagnostic, and Tree-sitter workflows have passed their recorded tests. The document remains **in progress** until the outstanding failure-path checks are completed or explicitly scoped out through a documented decision.

## 10. Out of scope

- Automatic installation of LuaLS, StyLua, or Tree-sitter parsers.
- Mason or another automatic tool installer.
- A separate Lua linting plugin without an accepted decision.
- A new language-server framework or formatter dispatcher.
- Global suppression of undefined-global diagnostics.
- Format-on-save without a separate decision.
- A Lua-specific replacement for the existing project-root workflow.

## References

- [Neovim LSP documentation](https://neovim.io/doc/user/lsp.html)
- [Neovim Tree-sitter documentation](https://neovim.io/doc/user/treesitter.html)
- [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig)
- [LuaLS configuration documentation](https://luals.github.io/wiki/configuration/)
- [LuaLS settings reference](https://luals.github.io/wiki/settings/)
- [StyLua](https://github.com/JohnnyMorganz/StyLua)
- [Conform.nvim](https://github.com/stevearc/conform.nvim)
- [lazydev.nvim](https://github.com/folke/lazydev.nvim)

Revisit this document when the shared language architecture, supported Neovim baseline, or Lua tooling requirements materially change.
