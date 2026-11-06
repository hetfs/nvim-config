# PowerShell Support

PowerShell support provides language intelligence, diagnostics, code navigation, completion, semantic highlighting, and formatting for PowerShell scripts in Neovim.

The implementation uses Neovim's native LSP client with PowerShell Editor Services (PSES). The `powershell.nvim` plugin manages the PSES lifecycle and integrates the server with Neovim.

## 1. Supported file types

| File extension | File type | Description |
|---|---|---|
| `.ps1` | `ps1` | PowerShell scripts |
| `.psm1` | `psm1` | PowerShell modules |
| `.psd1` | `psd1` | PowerShell data files and module manifests |

## 2. Architecture

| Component | Implementation |
|---|---|
| Language server | PowerShell Editor Services (PSES) |
| LSP integration | `powershell.nvim` |
| LSP client | Native Neovim LSP |
| Formatter | PSScriptAnalyzer `Invoke-Formatter` |
| Formatter integration | Conform.nvim |
| Parser | Treesitter `powershell` |
| Runtime | PowerShell 7+ (`pwsh`) |

### LSP ownership

`powershell.nvim` owns the PSES lifecycle, including server startup, session initialization, and communication setup with Neovim.

Neovim's native LSP client handles the language-server protocol connection and client capabilities.

Do not configure a separate `powershell_es` server through `vim.lsp.enable()`. This would introduce competing server ownership and could result in duplicate PSES sessions.

## 3. External dependencies

The PowerShell language pack requires the following external dependencies:

| Dependency | Purpose | Required |
|---|---|---|
| PowerShell 7+ | Runtime and command execution | Yes |
| PowerShell Editor Services | Language server | Yes |
| PSScriptAnalyzer | Formatting through `Invoke-Formatter` | Yes |

### Installation locations

PSES is installed under:

```text
%LOCALAPPDATA%\Programs\PSES\PowerShellEditorServices
```

The expected startup script is:

```text
PowerShellEditorServices\Start-EditorServices.ps1
```

The PowerShell executable is expected at:

```text
C:\Program Files\PowerShell\7\pwsh.exe
```

If PowerShell is installed elsewhere, update the executable path in the plugin configuration.

The installer and plugin configuration must use consistent PSES installation paths.

## 4. Installation

Use the external dependency installer:

```powershell
.\scripts\install\core\powershell.ps1
```

Check the installed dependencies without making changes:

```powershell
.\scripts\install\core\powershell.ps1 -Check
```

Update PSES and PSScriptAnalyzer:

```powershell
.\scripts\install\core\powershell.ps1 -Update
```

### Installation policy

The installer:

- Does not install PowerShell itself.
- Does not modify the system execution policy.
- Keeps external dependencies outside Neovim's plugin lifecycle.
- Supports checking and updating the PowerShell language tooling independently.

## 5. Plugin configuration

Entry point:

```text
lua/plugins/powershell.lua
```

Implementation:

```lua
vim.pack.add({
  {
    src = "https://github.com/TheLeoP/powershell.nvim",
    name = "powershell.nvim",
  },
})

require("powershell").setup({
  shell = "C:/Program Files/PowerShell/7/pwsh.exe",

  bundle_path = vim.fn.expand(
    "~/AppData/Local/Programs/PSES/PowerShellEditorServices"
  ),

  lsp_log_level = "Warning",

  settings = {
    powershell = {
      rename = {
        acceptDisclaimer = true,
      },
    },
  },
})
```

### Configuration notes

- `shell` specifies the PowerShell executable used to launch PSES.
- `bundle_path` points to the installed PowerShell Editor Services directory.
- `lsp_log_level` controls the PSES logging verbosity.
- `acceptDisclaimer` enables rename functionality without requiring repeated disclaimer confirmation.

The plugin is responsible for initializing the PowerShell language server. No separate `vim.lsp.enable("powershell_es")` configuration is required.

## 6. Language pack configuration

Entry point:

```text
lua/langs/powershell.lua
```

Implementation:

```lua
local M = {
  formatters = {
    ps1 = { "powershell_formatter" },
    psm1 = { "powershell_formatter" },
    psd1 = { "powershell_formatter" },
  },

  parser_by_filetype = {
    ps1 = "powershell",
    psm1 = "powershell",
    psd1 = "powershell",
  },
}

function M.setup()
  -- PSES initialization is owned by powershell.nvim.
end

return M
```

The language pack registers formatter and parser metadata with the central language registry.

LSP initialization remains the responsibility of `powershell.nvim`, keeping server management separate from language-pack metadata.

## 7. Keymaps

PowerShell terminal mappings and central LSP mappings are defined in:

```text
lua/config/keymaps.lua
```

### Keymap reference

| Keymap | Mode | Description | Ownership |
|---|---|---|---|
| `<leader>rn` | Normal | Rename symbol | Central LSP |
| `<leader>ca` | Normal | Code actions | Central LSP |
| `<leader>ps` | Normal | Open PowerShell terminal | PowerShell workflow |
| `<leader>pS` | Normal | Open vertical PowerShell terminal | PowerShell workflow |

### Implementation

The following mappings illustrate the intended behavior:

```lua
-- PowerShell and LSP workflows.

local map = vim.keymap.set

-- Central LSP operations.
map("n", "<leader>rn", vim.lsp.buf.rename, {
  desc = "LSP: Rename symbol",
})

map("n", "<leader>ca", vim.lsp.buf.code_action, {
  desc = "LSP: Code actions",
})

-- PowerShell terminal workflows.
map("n", "<leader>ps", function()
  vim.cmd("split")
  vim.cmd("terminal pwsh")
end, {
  desc = "PowerShell: Open terminal",
})

map("n", "<leader>pS", function()
  vim.cmd("vsplit")
  vim.cmd("terminal pwsh")
end, {
  desc = "PowerShell: Open vertical terminal",
})
```

**Ownership rules:**

- Rename and code actions belong to the central LSP configuration. If already registered through `LspAttach`, do not register them again.
- PowerShell terminal mappings belong to the general keymap configuration.
- Both terminal mappings launch PowerShell 7 through `pwsh`.
- All mappings include descriptions for which-key integration.

The terminal mappings are workflow conveniences and do not depend on PSES being attached.

## 8. Formatting

PowerShell formatting uses PSScriptAnalyzer's `Invoke-Formatter` through a custom Conform formatter.

Implementation:

```text
lua/config/formatters/powershell_formatter.lua
```

### Formatter responsibilities

The custom formatter:

1. Reads the current buffer content from standard input.
2. Normalizes line endings to Windows CRLF.
3. Invokes PSScriptAnalyzer's `Invoke-Formatter`.
4. Returns the formatted content through standard output.

### Formatting workflow

Formatting is manual:

```vim
:Format
```

Inspect the active formatter configuration:

```vim
:ConformInfo
```

Format-on-save remains disabled.

## 9. LSP capabilities

The following capabilities were validated with PowerShell Editor Services:

| Capability | Validation result |
|---|---|
| Diagnostics | Pass |
| Go to definition | Pass |
| Hover | Pass |
| Find references | Pass |
| Rename | Pass |
| Completion | Pass |
| Signature help | Pass |
| Document symbols | Pass |
| Workspace symbols | Pass |
| Document highlighting | Pass |
| Semantic tokens | Pass |
| CodeLens | Pass |
| Inlay hints | Not advertised by PSES |
| Code actions | No actions returned during validation |
| Folding | Server returned ranges; Neovim folding integration remains unresolved |

### Validation notes

The capability results distinguish between functionality that passed testing and functionality that was not advertised or did not produce usable results.

In particular:

- Inlay hints are not currently advertised by PSES.
- Code actions returned no available actions during validation.
- Folding ranges were returned by the server, but Neovim did not apply the expected folding behavior.

These results should not be interpreted as proof that the underlying protocol capabilities are universally unsupported.

## 10. Validation

Use a dedicated validation directory:

```text
%TEMP%\nvim-powershell-validation\
```

Test file:

```text
%TEMP%\nvim-powershell-validation\lsp-test.ps1
```

### Test script

```powershell
function Get-Greeting {
    param(
        [string]$Name
    )

    return "Hello, $Name"
}

Get-Greeting -Name "Neovim"
```

### Verify LSP attachment

Run:

```vim
:lua print(vim.inspect(vim.lsp.get_clients({ name = "powershell_es", bufnr = 0 })))
```

Expected client name:

```text
powershell_es
```

### Verify formatting

Run:

```vim
:Format
```

Inspect the formatter:

```vim
:ConformInfo
```

### Verify keymaps

Inspect the registered mappings:

```vim
:map <leader>rn
:map <leader>ca
:map <leader>ps
:map <leader>pS
```

Verify that:

- Rename and code actions are registered by the central LSP configuration.
- Both PowerShell terminal mappings are registered.
- The horizontal mapping opens a horizontal split.
- The vertical mapping opens a vertical split.
- Both terminal mappings launch `pwsh`.

### Validation requirements

Confirm that:

- PSES starts successfully.
- The `powershell_es` client attaches to PowerShell buffers.
- Diagnostics and language intelligence work.
- Code navigation and completion work.
- Rename functionality works.
- The custom Conform formatter executes successfully.
- PowerShell files are recognized by the Treesitter parser.
- All four documented keymaps work as expected.

## 11. Design decisions

The following decisions define the PowerShell language-pack implementation:

1. **Native LSP:** Use Neovim's native LSP client for language-server communication.
2. **PSES lifecycle:** Let `powershell.nvim` own PSES startup and session management.
3. **External dependencies:** Install and manage PowerShell tooling outside Neovim's plugin lifecycle.
4. **No Mason:** Do not use Mason to install or manage PowerShell tooling.
5. **Manual formatting:** Keep formatting explicitly user-triggered.
6. **Execution policy:** Never change the system execution policy automatically.
7. **Language registry:** Keep PowerShell support integrated with the central language-pack registry.
8. **Separation of concerns:** Keep LSP initialization in the plugin integration and formatter/parser metadata in the language pack.
9. **Centralized keymaps:** Keep user-facing mappings in `lua/config/keymaps.lua` and avoid duplicate LSP mappings.
10. **Terminal workflow:** Use `pwsh` for PowerShell terminal integration.
11. **Debugging scope:** Defer DAP integration to Stage 14. Do not introduce debugging configuration into Stage 13.

## 12. Completion status

**PowerShell support has passed its core Stage 13 language-pack integration and capability validation.**

| Area | Status |
|---|---|
| External dependency installation | Validated |
| PSES startup and integration | Validated |
| Native LSP attachment | Pass |
| Diagnostics and navigation | Pass |
| Completion and rename | Pass |
| Conform formatting | Validated |
| Treesitter integration | Registered |
| Central LSP keymaps | Documented |
| PowerShell terminal keymaps | Documented |
| Code actions | No actions returned during validation |
| Folding | Deferred; integration unresolved |
| DAP integration | Deferred to Stage 14 |

### Outstanding items

- Investigate Neovim folding integration with PSES-provided folding ranges.
- Revisit code actions if PSES exposes relevant actions in a future version.
- Validate all four keymaps in the running configuration.
- Keep debugging integration deferred until Stage 14.

**Stage 13 status:** Core PowerShell language support is complete. Folding remains a documented outstanding integration issue.
