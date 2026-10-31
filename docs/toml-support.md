# TOML Support

## Overview

The Stage 13 data-language pack provides TOML language support through Taplo, Conform, and Tree-sitter.

Taplo provides Language Server Protocol (LSP) features, including syntax diagnostics. Conform handles TOML formatting, while Tree-sitter provides syntax highlighting and folding support.

The implementation lives in `lua/langs/data.lua`, alongside YAML, JSON, JSONC, JSON5, and jq support.

### Design principles

- Use Taplo for TOML language-server support.
- Use Conform for formatting.
- Use Tree-sitter for syntax highlighting and folding.
- Keep TOML configuration inside the existing data-language pack.
- Reuse the existing LSP configuration and activation workflow.
- Enable the language server only when its executable is available.
- Avoid additional plugins and unnecessary modules.

## Dependencies

### Required

| Dependency | Purpose |
|---|---|
| Neovim >= 0.12.0 | Native LSP configuration and activation |
| Taplo | TOML language server and formatter |
| Tree-sitter TOML parser | Syntax highlighting and folding |

Taplo must be available through `PATH`.

### Windows installation

Install Taplo using Windows Package Manager:

```powershell
winget install --id tamasfe.taplo --exact
```

Verify the installation:

```powershell
Get-Command taplo
taplo --version
```

The tested installation used Taplo 0.10.0.

Official project: https://taplo.tamasfe.dev/

## Architecture

The implementation is contained in:

```text
lua/
└── langs/
    └── data.lua
```

The data-language pack owns:

- TOML filetype metadata.
- TOML Tree-sitter parser metadata.
- Taplo language-server activation.
- Taplo formatter configuration through Conform.

There is no separate `lua/config/toml.lua` module.

### Language server

The data-language pack uses the existing `taplo` server definition provided by `nvim-lspconfig`.

The server command is:

```lua
cmd = { "taplo", "lsp", "stdio" }
```

The server supports the `toml` filetype.

Its root markers are:

```lua
root_markers = {
  ".taplo.toml",
  "taplo.toml",
  ".git",
}
```

The existing data-language pack configures and enables the server through the shared native LSP workflow.

The server is enabled only when the `taplo` executable is available.

## Language features

### Diagnostics

Taplo provides TOML syntax diagnostics through Neovim's LSP client.

An invalid TOML document should produce a diagnostic in the current buffer.

For example, this incomplete TOML section is invalid:

```toml
[project
```

The tested configuration produced a severity 1 diagnostic from the Taplo language server, reported as `Even Better TOML`.

### Formatting

Conform uses Taplo as the TOML formatter.

The formatter registry includes:

| Filetype | Formatter |
|---|---|
| TOML | Taplo |

Formatter discovery can be inspected with:

```vim
:ConformInfo
```

The tested formatter discovery returned:

```lua
{
  available = true,
  command = "taplo",
  name = "taplo",
}
```

Format the current buffer manually with:

```vim
:Format
```

Formatting on save remains disabled by default. LSP formatting fallback is also disabled.

### Syntax highlighting and folding

Tree-sitter uses the `toml` parser for TOML files.

The parser is included in the existing Stage 08 Tree-sitter configuration.

The tested TOML buffer resolved to the TOML parser and displayed syntax highlighting successfully.

## Configuration boundaries

The TOML implementation follows the existing Stage 13 architecture.

| Responsibility | Component |
|---|---|
| Filetype detection | Neovim |
| Language-server features | Taplo |
| Formatting | Conform |
| Syntax highlighting | Tree-sitter |
| LSP configuration and activation | Native `vim.lsp` API |
| External executable installation | Windows installation scripts |

Taplo serves as both the language server and formatter. These responsibilities remain separate in the Neovim configuration: LSP handles language features, while Conform handles formatting.

No separate TOML plugin or configuration module is required.

## Validation

The TOML implementation was tested with Taplo 0.10.0 and Neovim 0.12.6.

### Installation checks

```powershell
Get-Command taplo
taplo --version
```

### Language-server checks

| Test | Expected behavior | Result |
|---|---|---|
| Open a `.toml` file | Taplo attaches to the buffer | Passed |
| Inspect the LSP client | `taplo` is the active client | Passed |
| Invalid TOML syntax | Displays an LSP diagnostic | Passed |
| Project root detection | Resolves using configured root markers | Passed |

The tested invalid TOML input was:

```toml
[project
```

Taplo reported the syntax error with severity 1.

### Formatter checks

| Test | Expected behavior | Result |
|---|---|---|
| Formatter discovery | Taplo is available for TOML | Passed |
| `:Format` | Formats the current TOML buffer | Passed |

### Tree-sitter checks

| Test | Expected behavior | Result |
|---|---|---|
| Open a TOML file | Resolves the `toml` parser | Passed |
| Syntax highlighting | TOML syntax is highlighted | Passed |

### Repository validation

Run the following commands from the repository root:

```powershell
stylua --check .
nvim --headless -u NONE -l scripts/check-syntax.lua
nvim --headless -u init.lua -c "luafile scripts/smoke.lua"
git diff --check
```

The repository-wide validation passed after the data-language pack changes:

- StyLua checks passed.
- All 33 Lua files passed syntax validation.
- The full smoke test passed all 17 reported checks.
- `git diff --check` reported no whitespace errors.

The smoke test validates the broader configuration. The TOML-specific LSP, formatter, and Tree-sitter results were confirmed through the interactive tests described above.

## Deliberate exclusions

The following features are outside the current implementation:

- A separate TOML configuration module.
- Additional TOML language-server plugins.
- Automatic Taplo installation during Neovim startup.
- Formatting on save.
- LSP formatting fallback.
- Additional TOML-specific formatting plugins.

These exclusions keep TOML support consistent with the data-language pack and the project's native-first architecture.

## References

- [Taplo documentation](https://taplo.tamasfe.dev/)
- [Taplo GitHub repository](https://github.com/tamasfe/taplo)
- [Taplo releases](https://github.com/tamasfe/taplo/releases)
- [Neovim LSP documentation](https://neovim.io/doc/user/lsp.html)
- [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig)
- [Conform.nvim](https://github.com/stevearc/conform.nvim)
- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)
