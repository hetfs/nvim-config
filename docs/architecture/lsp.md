# Language Server Protocol (LSP)

## Overview

Stage 09 integrates Neovim's native Language Server Protocol (LSP) client into `nvim-config`.

The design follows the project's native-first principle: **Neovim owns LSP configuration and activation; plugins provide supporting functionality.**

The integration separates shared LSP behavior from language-specific configuration. Language packs define the configuration for individual languages, while a small registry discovers and initializes those packs.

The initial implementation supports Lua development through Lua Language Server (LuaLS) and `lazydev.nvim`.

## Design principles

- **Native LSP first:** Use Neovim's `vim.lsp.config()` and `vim.lsp.enable()` APIs.
- **Clear responsibilities:** Keep plugin setup, shared LSP behavior, language configuration, and keymaps in separate modules.
- **Explicit plugin admission:** Manage plugin installation through Neovim's native `vim.pack`.
- **External tool management:** Install and manage language-server executables outside Neovim.
- **Local discovery:** Discover language packs from this configuration's own `lua/langs/` directory.
- **Incremental language support:** Add language-specific configuration through separate packs as the project evolves.
- **Direct module loading:** Load required modules explicitly from the root `init.lua`; do not introduce a separate configuration loader.

## Architecture

The LSP integration has five main components.

| Component | Responsibility |
|---|---|
| `lua/plugins/lsp.lua` | Installs `nvim-lspconfig`, which supplies language-server configurations. |
| `lua/plugins/lazydev.lua` | Installs and configures `lazydev.nvim` for Neovim-aware Lua development. |
| `lua/config/lsp.lua` | Registers shared behavior for the native `LspAttach` event. |
| `lua/config/keymaps.lua` | Defines LSP buffer-local keymaps through `M.lsp(bufnr)`. |
| `lua/langs/` | Contains the language-pack registry and language-specific configuration. |

### Startup flow

1. The root `init.lua` loads `plugins.lsp` to make the server configurations available.
2. It loads `plugins.lazydev` to configure Lua development support.
3. It loads the shared keymaps and LSP attachment handler.
4. It initializes the language-pack registry through `require("langs").setup()`.
5. The registry discovers and initializes the available language packs.
6. The Lua language pack configures and enables `lua_ls`.
7. When a server attaches to a buffer, the `LspAttach` handler registers the LSP buffer-local keymaps.

The existing root `init.lua` remains the explicit entry point for configuration startup.

## Language-pack design

The language-pack system separates language-specific configuration from shared LSP behavior.

### Registry: `lua/langs/init.lua`

The registry:

- Resolves the configuration's own `lua/langs/` directory.
- Discovers Lua files in that directory.
- Excludes `init.lua` from the list of language packs.
- Sorts discovered pack names for deterministic initialization order.
- Requires each discovered pack.
- Verifies that each pack provides a `setup()` function.
- Calls each pack's `setup()` function.

Language packs must therefore expose a `setup()` function. A malformed pack produces an explicit error rather than being silently accepted.

### Lua language pack: `lua/langs/lua.lua`

The Lua pack configures the `lua_ls` server using Neovim's native LSP API.

Its current settings include:

- LuaJIT as the runtime.
- The Neovim `vim` global for diagnostics.
- Disabled third-party workspace checks.
- Disabled LuaLS telemetry.

The pack enables the server using `vim.lsp.enable("lua_ls")`.

Server defaults, including the executable command, supported filetypes, and root markers, are supplied by the available `nvim-lspconfig` configuration unless an explicit override is needed.

### Adding another language

To introduce another language:

1. Add its server configuration in a new file under `lua/langs/`.
2. Implement the pack's `setup()` function.
3. Use Neovim's native LSP configuration and activation APIs.
4. Keep language-specific settings in that pack rather than in the shared LSP module.
5. Add appropriate validation and language-specific tests.

The registry discovers packs automatically, so adding a pack does not require a new entry in the registry. External language-server executables must still be installed and available on `PATH`.

## Shared LSP behavior and keymaps

### Attachment handler

`lua/config/lsp.lua` registers an autocmd for `LspAttach` in the `nvim_config_lsp` augroup.

When a language server attaches, the callback delegates buffer-local keymap registration to `require("config.keymaps").lsp(event.buf)`.

This keeps shared attachment behavior separate from language-specific server configuration.

### LSP keymaps

The `M.lsp(bufnr)` function in `lua/config/keymaps.lua` registers:

| Mapping | Action | Scope |
|---|---|---|
| `gd` | Go to definition | Buffer-local |
| `gD` | Go to declaration | Buffer-local |

The mappings use descriptive labels for discoverability.

A mapping being registered does not guarantee that every server supports its corresponding operation. For example, the current LuaLS client advertises definition support but does not advertise declaration support. Actual behavior depends on the attached server and its capabilities.

## Lua development support

`lazydev.nvim` improves LuaLS awareness of Neovim APIs and relevant Lua libraries.

It is configured separately in `lua/plugins/lazydev.lua`. It does **not** install the Lua language server.

The `lua-language-server` executable is an external dependency. It should be managed through the operating system, `mise`, or another suitable external tool-management workflow—not through Mason or a Neovim plugin.

This keeps the boundary between editor configuration and system-level tooling explicit.

## Dependencies and ownership

| Dependency or API | Role |
|---|---|
| Neovim native LSP | Configures and enables language servers; handles attachment and LSP operations. |
| `vim.pack` | Manages the Neovim plugin installations declared by this configuration. |
| `nvim-lspconfig` | Supplies language-server configuration definitions and defaults. |
| `lazydev.nvim` | Improves Lua development support. |
| `lua-language-server` | External executable that provides Lua language intelligence. |

The minimum supported Neovim version for this project is 0.12.0.

## Validation

Stage 09 is validated through syntax checks, formatting checks, smoke tests, and interactive LSP verification.

From the repository root, run:

```powershell
stylua --check .
nvim --headless -u NONE -l scripts/check-syntax.lua
nvim --headless -u init.lua -c "luafile scripts/smoke.lua"
git diff --check
```

The smoke test checks the LSP plugin modules, language-pack registry, Lua server configuration, expected Lua settings, server activation, shared attachment handler, and keymap registration function. It also checks existing configuration stages for regressions.

Interactive verification complements these automated checks:

- Confirm that LuaLS attaches to a Lua buffer.
- Verify diagnostics and hover behavior.
- Verify definition navigation.
- Check the registered declaration mapping while accounting for server capabilities.

Automated configuration checks alone do not prove that every language server can start, attach, or provide every LSP operation.

## Current scope and future extension

Stage 09 establishes the shared LSP foundation and initial Lua support. It does not attempt to configure every language server or install all language tooling.

Additional language packs and their external tools can be introduced in later stages. The shared attachment handler and keymap interface should remain language-agnostic unless a concrete requirement justifies a change.

The guiding rule is to keep shared behavior centralized, language-specific behavior localized, and external tooling independent of Neovim plugin management.
