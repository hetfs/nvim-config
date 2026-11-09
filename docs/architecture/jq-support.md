# jq Support

## Overview

The Stage 13 data-language pack provides native jq execution inside Neovim.

The implementation uses Neovim's built-in `vim.system()` API to execute the external `jq` command asynchronously. It passes input through standard input and captures the output without requiring temporary files or an additional plugin.

The implementation lives in `lua/langs/data.lua`, alongside JSON, YAML, and TOML support.

### Design principles

- Use Neovim's native APIs for command execution.
- Keep jq execution inside the existing data-language pack.
- Avoid additional plugins and unnecessary modules.
- Preserve the source buffer.
- Display successful results in a reusable scratch buffer.
- Keep jq execution separate from Conform formatting.
- Enable optional language servers only when their executables are available.

## Dependencies

### Required

| Dependency | Purpose |
|---|---|
| Neovim >= 0.12.0 | Native `vim.system()` support |
| jq | JSON processing and filter execution |

The jq executable must be available through `PATH`.

### Optional

| Dependency | Purpose |
|---|---|
| jq-lsp | Language-server support for jq filter files |

The jq language server is optional. Neovim enables it only when the `jq-lsp` executable is available.

The server definition is provided by `nvim-lspconfig`.

### Windows installation

Install jq using Windows Package Manager:

```powershell
winget install --id jqlang.jq --exact
```

Verify the installation:

```powershell
Get-Command jq
jq --version
```

The tested installation used jq 1.8.2.

Official downloads: https://jqlang.org/download/

## Architecture

The implementation is contained in:

```text
lua/
└── langs/
    └── data.lua
```

The data-language pack owns:

- jq filetype metadata.
- jq Tree-sitter parser metadata.
- Optional jq language-server activation.
- Native jq command execution.
- The `:Jq` user command.

There is no separate `lua/config/jq.lua` module.

### Execution flow

```text
User invokes :Jq or <leader>jq
             |
             v
       Collect jq filter
             |
             v
       Read source buffer
             |
             v
       Build jq argument list
             |
             v
       vim.system() executes jq
             |
             v
       Process completion callback
             |
        +----+----+
        |         |
      Error     Success
        |         |
        v         v
    Notify     Update reusable
     user      scratch buffer
                  |
                  v
             Return focus
             to source window
```

## Commands

### `:Jq`

Run a jq filter against the entire current buffer.

```vim
:Jq
```

The default filter is `.`.

Apply a property filter:

```vim
:Jq .name
```

Iterate over an array:

```vim
:Jq .features[]
```

### `:Jq!`

The bang form enables jq's raw output option (`-r`).

```vim
:Jq! .name
```

This is useful when extracting strings without JSON quotation marks.

### Range execution

The command supports Vim ranges.

For example, select JSON lines in Visual mode and execute:

```vim
:'<,'>Jq .
```

Only the selected lines are passed to jq.

Without a range, the entire current buffer is used.

## Interactive filter prompt

The data pack exposes:

```lua
require("langs.data").run_prompt()
```

This opens Neovim's native `vim.ui.input()` prompt.

The default filter is:

```jq
.
```

Enter a jq expression and press Enter to execute it.

Pressing `Esc` cancels the prompt without executing jq.

The existing normal-mode mapping invokes this function:

```lua
vim.keymap.set("n", "<leader>jq", function()
  require("langs.data").run_prompt()
end, {
  desc = "Run jq filter",
})
```

## Output handling

Successful jq execution displays its output in a reusable scratch buffer.

The result buffer uses:

- `buftype=nofile`
- `bufhidden=hide`
- `swapfile=false`
- Read-only content after each update.
- A buffer-local `q` mapping to close the result window.

The result buffer is reused across executions rather than creating a new buffer every time.

Results are displayed in a vertical split.

After displaying the result, focus returns to the original source window. This allows repeated jq execution against the same source buffer without accidentally processing the previous result.

The source buffer is never replaced by jq output.

## Error handling

The implementation checks whether jq is available before execution.

If jq is missing, Neovim displays an error notification.

When jq returns a non-zero exit code, its standard error output is displayed through `vim.notify()`.

Invalid filters do not replace the previous successful result.

The implementation uses asynchronous execution, so Neovim remains responsive while jq processes input.

## Formatting and language-server boundaries

### Formatting

Conform remains responsible for formatting supported data filetypes.

The configured formatters are:

| Filetype | Formatter |
|---|---|
| YAML | Prettier |
| JSON | Prettier |
| JSONC | Prettier |
| JSON5 | Prettier |
| TOML | Taplo |

jq is intentionally excluded from the Conform formatter registry.

The `jq` executable processes JSON data using jq expressions. It is not a formatter for jq filter source files.

No jq filter formatter is currently configured.

### Language server

The jq language server is optional.

The data pack attempts to enable `jqls` only when `jq-lsp` is available.

No LSP formatting is configured for jq.

## Validation

The jq implementation was tested with jq 1.8.2 and Neovim 0.12.6.

### Installation checks

```powershell
Get-Command jq
jq --version
```

### Independent jq checks

```powershell
'{"name":"Neovim","version":"0.12.6"}' | jq .
'{"name":"Neovim","version":"0.12.6"}' | jq '.name'
'{"name":"Neovim","version":"0.12.6"}' | jq -r '.name'
'{"features":["native","Lua","jq"]}' | jq '.features[]'
```

### Neovim checks

| Test | Expected behavior |
|---|---|
| `:Jq` | Returns the current buffer as JSON |
| `:Jq .name` | Extracts the name property |
| `:Jq! .name` | Returns the name without JSON quotation marks |
| `:Jq .features[]` | Iterates over array elements |
| Visual range with `:Jq` | Processes only selected lines |
| Invalid filter | Displays an error notification |
| Missing jq executable | Displays an error notification |
| `<leader>jq` | Opens the interactive filter prompt |
| Prompt cancellation | Cancels without executing |
| Repeated execution | Reuses the result buffer |
| Source-window focus | Returns focus to the original source window |
| Source preservation | Leaves the source buffer unchanged |

### Static validation

```powershell
stylua lua/langs/data.lua
stylua --check lua/langs/data.lua
nvim -l scripts/check-syntax.lua
```

The implementation passed the reported static and interactive checks.

## Deliberate exclusions

The following features are not part of the current implementation:

- jqfmt integration.
- jq formatting through Conform.
- Automatic jq installation during Neovim startup.
- A separate jq configuration module.
- Additional jq execution plugins.
- Automatic modification of the source buffer.

These exclusions keep jq execution small, native, and independent of the formatting and LSP workflows.

## References

- jq official website: https://jqlang.org/
- jq downloads: https://jqlang.org/download/
- jq manual: https://jqlang.org/manual/
- Neovim API documentation: https://neovim.io/doc/user/lua.html
