# Data Language Pack

## Overview

The Stage 13 data-language pack provides support for structured data formats in Neovim.

It brings YAML, JSON, JSONC, JSON5, jq, and TOML support together in `lua/langs/data.lua`.

The pack uses existing Neovim capabilities and approved plugins to provide language-server features, formatting, syntax highlighting, and native jq execution.

### Supported formats

| Format | Language server | Formatter | Tree-sitter parser |
|---|---|---|---|
| YAML | YAML Language Server | Prettier | `yaml` |
| JSON | JSON Language Server | Prettier | `json` |
| JSONC | JSON Language Server | Prettier | `json` |
| JSON5 | Not configured | Prettier | `json5` |
| jq | Optional `jq-lsp` | None | `jq` |
| TOML | Taplo | Taplo | `toml` |

The JSON Language Server handles JSON and JSONC. JSON5 deliberately uses Tree-sitter and Prettier without JSON Language Server attachment.

## Design principles

- Keep related data-language configuration in one pack.
- Use native Neovim LSP configuration and activation.
- Use Conform as the formatting interface.
- Use Tree-sitter for syntax highlighting and folding.
- Enable optional language servers only when their executables are available.
- Keep jq execution separate from formatting.
- Avoid unnecessary plugins and configuration modules.
- Do not install external tools automatically during Neovim startup.

## Architecture

The implementation is contained in:

```text
lua/
└── langs/
    └── data.lua
```

The data-language pack owns:

- Data filetype metadata.
- Formatter metadata.
- Tree-sitter parser metadata.
- Language-server configuration and activation.
- Native jq command execution.
- The interactive jq filter prompt.

There are no separate configuration modules for YAML, JSON, jq, or TOML.

### Integration boundaries

| Responsibility | Component |
|---|---|
| Filetype detection | Neovim |
| Language-server configuration | Native `vim.lsp` API |
| Language-server definitions | `nvim-lspconfig` |
| Formatting | Conform |
| Syntax highlighting and folding | nvim-treesitter |
| jq execution | Native `vim.system()` API |
| External tool installation | Windows installation scripts |

The pack uses the existing `langs` registry to expose its metadata.

It does not introduce another plugin manager, language-server manager, or external tool installer.

## Filetype support

The pack registers the following filetypes:

| Format | Filetypes |
|---|---|
| YAML | `yaml`, `yaml.docker-compose`, `yaml.ansible`, `yaml.gitlab`, `yaml.helm-values` |
| JSON | `json` |
| JSONC | `jsonc` |
| JSON5 | `json5` |
| jq | `jq` |
| TOML | `toml` |

The YAML variants are supported by the same YAML parser and language server.

JSONC uses the JSON Tree-sitter parser. JSON5 uses its dedicated parser.

## Language-server support

The pack configures and enables language servers through Neovim's native LSP API.

Server activation is conditional on the corresponding executable being available.

### YAML Language Server

| Property | Configuration |
|---|---|
| Server | `yamlls` |
| Executable | `yaml-language-server` |
| Filetypes | YAML and supported YAML variants |
| SchemaStore | Disabled |
| Telemetry | Disabled |
| LSP formatting | Disabled |

YAML validation is enabled.

The configured filetypes are:

- `yaml`
- `yaml.docker-compose`
- `yaml.ansible`
- `yaml.gitlab`
- `yaml.helm-values`

SchemaStore integration remains disabled. Project-owned schemas and modelines are preferred.

### JSON Language Server

| Property | Configuration |
|---|---|
| Server | `jsonls` |
| Executable | `vscode-json-language-server` |
| Filetypes | `json`, `jsonc` |
| Validation | Enabled |
| LSP formatting | Disabled |
| Schema associations | Empty |

JSON5 is deliberately excluded from the server's filetypes.

The JSON Language Server provides diagnostics for JSON and JSONC documents.

JSON Schema associations and schema validation have not yet been configured or validated.

### jq Language Server

| Property | Configuration |
|---|---|
| Server | `jqls` |
| Executable | `jq-lsp` |
| Filetype | `jq` |
| Availability | Optional |

The pack enables the jq language server only when `jq-lsp` is available.

No LSP formatting is configured for jq.

### Taplo

| Property | Configuration |
|---|---|
| Server | `taplo` |
| Executable | `taplo` |
| Filetype | `toml` |
| Command | `taplo lsp stdio` |

Taplo provides TOML language-server support, including syntax diagnostics.

Its root markers are:

```lua
{
  ".taplo.toml",
  "taplo.toml",
  ".git",
}
```

## Formatting

Conform handles formatting for supported data filetypes.

| Filetype | Formatter |
|---|---|
| YAML | Prettier |
| `yaml.docker-compose` | Prettier |
| `yaml.ansible` | Prettier |
| `yaml.gitlab` | Prettier |
| `yaml.helm-values` | Prettier |
| JSON | Prettier |
| JSONC | Prettier |
| JSON5 | Prettier |
| TOML | Taplo |

jq is intentionally excluded from the formatter registry.

The jq executable processes JSON data using jq expressions. It does not format jq filter source files.

No jq filter formatter is configured.

### Formatting policy

Formatting is manual through the existing Conform workflow:

```vim
:Format
```

Formatting on save remains disabled by default.

LSP formatting fallback is also disabled.

## Tree-sitter support

The data-language pack exposes parser metadata for:

| Format | Parser |
|---|---|
| YAML | `yaml` |
| JSON | `json` |
| JSONC | `json` |
| JSON5 | `json5` |
| jq | `jq` |
| TOML | `toml` |

The existing Stage 08 Tree-sitter configuration handles parser installation and highlighting.

YAML variants resolve to the `yaml` parser.

JSONC resolves to the `json` parser, while JSON5 uses the dedicated `json5` parser.

TOML highlighting was tested successfully.

## Native jq execution

The data-language pack implements jq execution using Neovim's built-in `vim.system()` API.

It does not require a separate execution plugin or temporary files.

### Commands

Run jq against the entire current buffer:

```vim
:Jq
```

The default filter is `.`.

Apply a filter:

```vim
:Jq .name
```

Use raw output:

```vim
:Jq! .name
```

Process a selected range:

```vim
:'<,'>Jq .
```

The bang form enables jq's raw output option (`-r`).

### Interactive prompt

The pack exposes:

```lua
require("langs.data").run_prompt()
```

The function opens Neovim's native `vim.ui.input()` prompt.

The normal-mode mapping is:

```lua
vim.keymap.set("n", "<leader>jq", function()
  require("langs.data").run_prompt()
end, {
  desc = "Run jq filter",
})
```

Pressing `Esc` cancels the prompt without executing jq.

### Output handling

Successful execution displays the result in a reusable scratch buffer.

The result buffer:

- Uses `buftype=nofile`.
- Uses `bufhidden=hide`.
- Disables swap files.
- Becomes read-only after updates.
- Uses a buffer-local `q` mapping to close the result window.

Results appear in a vertical split.

After displaying the result, focus returns to the original source window. The source buffer remains unchanged.

### Error handling

The implementation checks whether jq is available before execution.

If jq is missing, Neovim displays an error notification.

If jq returns a non-zero exit code, its standard error output is displayed through `vim.notify()`.

Invalid filters do not replace the previous successful result.

Execution is asynchronous, keeping Neovim responsive while jq processes the input.

## Dependencies

### Required external tools

| Tool | Purpose |
|---|---|
| `yaml-language-server` | YAML language-server support |
| `vscode-json-language-server` | JSON and JSONC language-server support |
| `prettier` | YAML, JSON, JSONC, and JSON5 formatting |
| `jq` | JSON processing and filter execution |
| `taplo` | TOML language-server support and formatting |

### Optional external tools

| Tool | Purpose |
|---|---|
| `jq-lsp` | jq language-server support |

Tree-sitter parsers are managed through the existing Tree-sitter configuration.

All external executables must be available through `PATH` for their respective features to work.

## Windows installation scripts

External tools for the data-language pack are installed through dedicated PowerShell scripts.

The single entry point is:

```text
scripts/
└── install/
    └── windows/
        ├── data-pack.ps1
        ├── yaml.ps1
        ├── json.ps1
        ├── jq-lsp.ps1
        └── toml.ps1
```

### Installation responsibilities

| Script | Responsibility |
|---|---|
| `data-pack.ps1` | Main entry point. Runs the individual data-pack installers in sequence. |
| `yaml.ps1` | Installs and verifies YAML Language Server and Prettier. |
| `json.ps1` | Installs and verifies JSON Language Server and Prettier. |
| `jq-lsp.ps1` | Installs and verifies the jq Language Server. |
| `toml.ps1` | Installs and verifies Taplo. |

The individual scripts own their installation and verification logic. `data-pack.ps1` orchestrates them and provides one command for installing the data-pack tools.

The execution order is:

1. `yaml.ps1`
2. `json.ps1`
3. `jq-lsp.ps1`
4. `toml.ps1`

The orchestrator stops if an installer fails.

The `jq` executable is installed separately. `data-pack.ps1` checks that `jq` is available before running the individual installers.

### Run the installer

From the repository root:

```powershell
.\scripts\install\windows\data-pack.ps1
```

Run this script after adding or updating the individual data-pack installation scripts.

### Verify executable discovery in Neovim

Installation is complete when the external tools are installed and verified. The next step is to confirm that Neovim can discover their executables.

Run the following commands inside Neovim:

```vim
:lua print(vim.fn.executable("yaml-language-server"))
:lua print(vim.fn.executable("vscode-json-language-server"))
:lua print(vim.fn.executable("jq-lsp"))
:lua print(vim.fn.executable("taplo"))
:lua print(vim.fn.executable("prettier"))
:lua print(vim.fn.executable("jq"))
```

Each command should return:

```text
1
```

A return value of `1` means Neovim can find the executable through its `PATH`. A return value of `0` means the executable is not discoverable.

This check verifies executable discovery only. Language-server attachment and feature behavior must be validated separately inside Neovim.

## Validation

The data-language pack was tested with Neovim 0.12.6.

### YAML

| Test | Result |
|---|---|
| YAML Language Server attachment | Passed |
| Standard YAML diagnostics | Passed |
| Completion and hover | Passed |
| YAML Tree-sitter highlighting | Passed |
| Prettier formatter discovery | Passed |
| `:Format` execution | Passed |
| YAML variant filetype support | Passed |
| YAML variant formatter discovery | Passed |
| YAML variant formatting | Passed |

The five supported YAML filetypes were checked.

Separate diagnostic tests for every YAML dialect were not performed.

### JSON, JSONC, and JSON5

| Test | Result |
|---|---|
| JSON Language Server attachment | Passed |
| JSON diagnostics | Passed |
| JSONC Language Server attachment | Passed |
| JSONC diagnostics | Passed |
| JSON Tree-sitter support | Passed |
| JSONC Tree-sitter support | Passed |
| JSON5 Tree-sitter support | Passed |
| JSON formatting | Passed |
| JSONC formatting | Passed |
| JSON5 formatting | Passed |

JSON5 intentionally has no JSON Language Server attachment.

JSON Schema associations and validation remain pending.

Special filename detection, including `tsconfig.json`, `jsconfig.json`, `.vscode/settings.json`, and `.vscode/launch.json`, has not been separately validated.

### jq

| Test | Result |
|---|---|
| jq CLI execution | Passed |
| Property selection | Passed |
| Raw output | Passed |
| Array iteration | Passed |
| `:Jq` | Passed |
| `:Jq!` | Passed |
| Visual range execution | Passed |
| Invalid filter handling | Passed |
| Missing executable handling | Passed |
| Interactive prompt | Passed |
| Prompt cancellation | Passed |
| Repeated execution | Passed |
| Result-buffer reuse | Passed |
| Source-window focus | Passed |
| Source-buffer preservation | Passed |
| jq language-server attachment | Passed |
| jq syntax diagnostics | Passed |

### TOML

| Test | Result |
|---|---|
| Taplo language-server attachment | Passed |
| TOML syntax diagnostics | Passed |
| Project root detection | Passed |
| Taplo formatter discovery | Passed |
| `:Format` execution | Passed |
| TOML Tree-sitter highlighting | Passed |

### Repository validation

The following checks passed after the data-language pack changes:

```powershell
stylua --check .
nvim --headless -u NONE -l scripts/check-syntax.lua
nvim --headless -u init.lua -c "luafile scripts/smoke.lua"
git diff --check
```

Reported results:

- StyLua checks passed.
- All 33 Lua files passed syntax validation.
- The full smoke test passed all 17 reported checks.
- `git diff --check` reported no whitespace errors.

The smoke test validates the broader configuration. The language-specific results above were confirmed through separate interactive tests.

## Pending work

The following items remain outside the validated implementation:

- JSON Schema associations and schema validation.
- Special JSONC filename detection.
- Manual `<leader>cf` formatting-keymap verification.
- Separate diagnostic testing for every YAML dialect.
- Optional SchemaStore integration.
- Optional jq filter formatting.

These items should be evaluated independently before being added to the supported feature set.

## Deliberate exclusions

The data-language pack does not include:

- Automatic external tool installation during Neovim startup.
- Mason-based tool management.
- A separate configuration module for each data format.
- SchemaStore integration by default.
- jq formatting through Conform.
- jqfmt integration.
- LSP formatting fallback.
- Formatting on save by default.
- Additional data-language execution plugins.

These boundaries keep data-language support centralized while allowing each tool to own its specific responsibility.

## Format-specific documentation

The following documents provide detailed configuration, installation, usage, and validation information for each supported format:

- [YAML support](yaml-support.md)
- [JSON support](json-support.md)
- [jq support](jq-support.md)
- [TOML support](toml-support.md)

All four documents are located in the `docs/` directory alongside `data-pack.md`.

## References

- [YAML Language Server](https://github.com/redhat-developer/yaml-language-server)
- [Prettier](https://prettier.io/)
- [JSON Language Server](https://github.com/microsoft/vscode/tree/main/extensions/json-language-features/server)
- [jq official website](https://jqlang.org/)
- [jq manual](https://jqlang.org/manual/)
- [jq-lsp](https://github.com/wader/jq-lsp)
- [Taplo documentation](https://taplo.tamasfe.dev/)
- [Taplo GitHub repository](https://github.com/tamasfe/taplo)
- [Neovim LSP documentation](https://neovim.io/doc/user/lsp.html)
- [Conform.nvim](https://github.com/stevearc/conform.nvim)
- [nvim-treesitter](https://github.com/nvim-treesitter)
