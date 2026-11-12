# MDX Support

- **Status:** Implemented; core language-server, formatting, and parser workflows validated
- **Last validated:** 2026-11-12
- **Roadmap stage:** Stage 13 — Language Packs
- **Validated environment:** Windows, Neovim 0.12.6, PowerShell 7.6.9
- **Language server:** `@mdx-js/language-server` 0.6.4
- **Formatter:** dprint with `dprint-plugin-mdx`

## 1. Purpose

Define the architecture, dependencies, configuration, installation, and validation requirements for MDX support in `nvim-config`.

MDX combines Markdown with JSX and JavaScript expressions. It requires tooling that understands both Markdown syntax and embedded JavaScript or TypeScript constructs.

The implementation uses the existing language-pack architecture and shared Neovim infrastructure. It does not introduce another plugin manager, language-server manager, or formatter integration.

## 2. Design Principles

- Use Neovim's native LSP configuration and activation APIs.
- Keep MDX-specific configuration in `lua/langs/mdx.lua`.
- Reuse the existing `langs` registry and Conform formatting workflow.
- Use Tree-sitter for syntax parsing and highlighting.
- Keep external tool installation separate from Neovim startup.
- Use dprint with its MDX plugin for formatting.
- Preserve upstream language-server defaults unless the MDX pack needs to override them.
- Keep formatting manual through `:Format`.
- Keep format-on-save disabled by default.
- Do not introduce LSP formatting fallback.
- Validate Markdown, JSX, expressions, and embedded TypeScript independently.

## 3. Architecture

MDX support is distributed across the existing configuration modules.

```text
lua/
├── langs/
│   └── mdx.lua
└── plugins/
    └── treesitter.lua

scripts/
└── core/
    └── windows/
        └── mdx.ps1
```

| Component | Responsibility |
|---|---|
| `lua/langs/mdx.lua` | MDX formatter metadata and language-server configuration |
| `lua/plugins/treesitter.lua` | Custom MDX parser registration |
| `lua/langs/init.lua` | Existing language-pack registration and metadata collection |
| `lua/config/format.lua` | Existing manual formatting workflow through Conform |
| `scripts/core/windows/mdx.ps1` | Windows MDX toolchain installation and verification |
| Workspace `dprint.json` | dprint plugin selection and MDX formatting options |
| Workspace `package.json` | Workspace TypeScript dependency |

The MDX pack does not own a separate formatter runner or Tree-sitter configuration module.

## 4. Integration Boundaries

| Responsibility | Component |
|---|---|
| Filetype detection | Neovim |
| Language-server configuration | Native `vim.lsp` API |
| Language-server definition | `nvim-lspconfig` |
| Language features | `@mdx-js/language-server` |
| TypeScript integration | MDX TypeScript plugin and workspace TypeScript |
| Formatting | Conform |
| MDX formatting implementation | dprint MDX plugin |
| Embedded TypeScript formatting | dprint TypeScript plugin |
| Syntax parsing and highlighting | nvim-treesitter |
| Parser grammar | `tree-sitter-mdx` |
| External tool installation | Windows installation script and mise |

These components have separate responsibilities. The language server does not replace the formatter, and the formatter does not provide language-server diagnostics.

## 5. Filetype Support

The language pack uses the `mdx` filetype.

| Format | Filetype | Tree-sitter parser |
|---|---|---|
| MDX | `mdx` | `mdx` |

The parser handles the combined document structure, including Markdown blocks, JSX elements, JavaScript expressions, and supported embedded code constructs.

## 6. Language Server

**Package:** `@mdx-js/language-server`

**Configured server:** `mdx_analyzer`

The MDX language server provides diagnostics and TypeScript-backed language features for MDX documents.

The implementation uses Neovim's native LSP APIs:

- `vim.lsp.config()` configures the server.
- `vim.lsp.enable()` enables the server.
- `nvim-lspconfig` supplies the maintained server definition.

The implementation does not use the legacy `require("lspconfig")` interface.

### 6.1 Configuration

The MDX pack resolves the server executable through `vim.fn.exepath()`.

```lua
local M = {
  formatters = {
    mdx = { "dprint" },
  },

  parser_by_filetype = {
    mdx = "mdx",
  },
}

function M.setup()
  local executable = vim.fn.exepath("mdx-language-server")

  if executable == "" then
    vim.notify(
      "MDX language server not found: mdx-language-server",
      vim.log.levels.WARN
    )
    return
  end

  vim.lsp.config("mdx_analyzer", {
    cmd = {
      executable,
      "--stdio",
    },

    init_options = {
      typescript = {
        enabled = true,
      },
    },
  })

  vim.lsp.enable("mdx_analyzer")
end

return M
```

The server definition retains its upstream defaults, including filetypes, root markers, and TypeScript SDK discovery.

The MDX pack enables TypeScript integration without hardcoding a TypeScript SDK path. This allows the language server to discover the appropriate workspace TypeScript installation.

### 6.2 Language-server validation

The following behavior has been interactively verified:

- The `mdx_analyzer` server starts.
- The server attaches to MDX buffers.
- The expected workspace root is detected.
- Diagnostics are available.
- Completion works.
- TypeScript-backed language features are enabled.

The executable is installed independently of Neovim plugin installation.

## 7. TypeScript Integration

MDX uses TypeScript infrastructure for embedded JavaScript and TypeScript language features.

The workspace dependency is:

```text
typescript@6.0.3
```

The MDX TypeScript plugin is:

```text
@mdx-js/typescript-plugin
```

TypeScript belongs to the workspace dependency layer rather than the global Neovim plugin configuration.

The language server is responsible for discovering the workspace TypeScript SDK. The MDX pack should not hardcode a machine-specific SDK path.

### Workspace requirements

A workspace using the MDX development toolchain should provide:

- `package.json`
- `dprint.json`
- The required TypeScript version
- The dprint plugins declared in its formatter configuration

The Windows installer can check and install the exact TypeScript version when run in workspace mode.

## 8. Formatting

**Formatter:** dprint

**MDX plugin:** `dprint-plugin-mdx`

**TypeScript plugin:** `@dprint/typescript`

Documentation:

- https://dprint.dev/
- https://github.com/dprint/dprint-plugin-mdx

Formatting uses the existing manual interface through `:Format` and Conform.

The MDX language pack declares dprint as its formatter:

```lua
formatters = {
  mdx = { "dprint" },
}
```

The formatter configuration remains in the workspace. The Neovim language pack does not duplicate dprint plugin configuration.

### 8.1 Workspace configuration

The tested `dprint.json` configuration is:

```json
{
  "lineWidth": 80,
  "plugins": [
    "npm:dprint-plugin-mdx",
    "npm:@dprint/typescript@0.100.0"
  ],
  "mdx": {
    "textWrap": "maintain"
  }
}
```

The MDX plugin handles MDX document formatting. The TypeScript plugin handles supported TypeScript code formatting, including TypeScript code fences.

The `textWrap` setting preserves existing Markdown text wrapping rather than introducing unnecessary paragraph reflow.

### 8.2 Formatting validation

Formatting was tested using a representative MDX fixture containing:

- Markdown headings and paragraphs.
- Markdown emphasis and inline code.
- Lists and links.
- MDX imports and exports.
- JavaScript expressions.
- JSX elements and attributes.
- Embedded TypeScript code fences.

The formatter was verified both through standalone dprint execution and through Neovim's `:Format` workflow.

The tests confirmed that formatting preserves the MDX document structure and formats supported embedded TypeScript.

Formatting remains independent of language-server diagnostics and Tree-sitter parsing.

## 9. Tree-sitter Parser

**Parser:** `mdx`

**Grammar repository:** https://github.com/srazzak/tree-sitter-mdx

The installed nvim-treesitter version uses its legacy parser registry API. The MDX parser is therefore registered through the existing `TSUpdate` event in:

```text
lua/plugins/treesitter.lua
```

The registration is:

```lua
vim.api.nvim_create_autocmd("User", {
  pattern = "TSUpdate",
  callback = function()
    require("nvim-treesitter.parsers").mdx = {
      install_info = {
        url = "https://github.com/srazzak/tree-sitter-mdx",
        queries = "queries",
      },
      tier = 1,
    }
  end,
})
```

This registration belongs in the existing Tree-sitter plugin module. A separate `lua/config/treesitter.lua` module is not required.

### 9.1 Parser validation

The parser was installed successfully.

The resulting syntax tree was inspected with `:InspectTree`. The inspected fixture included:

- Import and export statements.
- Markdown headings and paragraphs.
- Lists and links.
- Fenced code blocks.
- JSX opening and closing elements.
- JSX attributes and text.
- JavaScript expressions.
- Embedded TypeScript content.

The inspection confirmed that the grammar recognizes the main MDX document constructs.

One tested edge case produced an `ERROR` node where a heading marker was followed by a JSX expression. This is recorded as a grammar edge case, not a parser installation failure.

Further grammar changes should be based on a reproducible fixture and confirmed parser behavior.

## 10. Windows Toolchain

The Windows installation entry point is:

```powershell
.\scripts\core\windows\mdx.ps1
```

The installer uses mise to manage global tools.

### 10.1 Global dependencies

| Tool | Version or package | Scope |
|---|---|---|
| Node.js | 26.x | Global |
| dprint | 0.64.3 | Global |
| MDX language server | `@mdx-js/language-server@0.6.4` | Global |
| npm | Bundled with Node.js | Global runtime |
| Tree-sitter CLI | 0.27.1 | Existing external tool |
| Native compiler | Existing GCC or Clang toolchain | Existing external tool |

The native compiler and Tree-sitter CLI are checked by the installer. They are not installed by this script.

### 10.2 Installation modes

The installer supports two modes.

**Global mode**

```powershell
.\scripts\core\windows\mdx.ps1
```

This installs the global MDX tools through mise and verifies the available runtime and formatter commands.

**Workspace mode**

```powershell
.\scripts\core\windows\mdx.ps1 `
  -WorkspacePath "C:\path\to\workspace"
```

Workspace mode additionally requires:

- An existing workspace directory.
- A `package.json` file.
- A `dprint.json` file.

It checks the workspace TypeScript installation and installs `typescript@6.0.3` as an exact development dependency when necessary. It also verifies that the required dprint plugins are declared in `dprint.json`.

The current installer uses npm for this workspace dependency operation.

### 10.3 Installation record

The global installation completed successfully on Windows.

Verified installation output:

| Component | Result |
|---|---|
| mise | Available |
| Node.js | 26.13.1 installed |
| npm | 11.20.0 available |
| dprint | 0.64.3 installed |
| MDX language server package | 0.6.4 installed |
| Tree-sitter CLI | 0.27.1 available |
| Native compiler | Available |

Global installation success does not, by itself, establish that every workspace dependency has been installed. Workspace mode remains the separate check for TypeScript and dprint configuration.

## 11. Validation Record

| Area | Validation | Status |
|---|---|---|
| Language-pack configuration | MDX pack loads through the existing registry | Implemented |
| Native LSP configuration | `mdx_analyzer` configured and enabled | Verified |
| LSP attachment | Server attaches to MDX buffers | Verified |
| Diagnostics | MDX diagnostics available | Verified |
| Completion | Completion works | Verified |
| TypeScript integration | TypeScript-backed language features tested | Verified |
| Formatter metadata | dprint registered for `mdx` | Implemented |
| Standalone formatting | dprint formats the representative fixture | Verified |
| Conform integration | `:Format` invokes dprint | Verified |
| Tree-sitter registration | Custom MDX parser registered | Implemented |
| Parser installation | MDX parser installed | Verified |
| Syntax-tree inspection | Main MDX constructs recognized | Verified |
| Grammar edge case | Heading followed by JSX expression produces an `ERROR` node | Known limitation |
| Global tool installation | mise installation completed | Verified |
| Workspace installer mode | TypeScript and dprint workspace checks | Pending execution |

## 12. Acceptance Criteria

MDX support is considered complete when:

1. The MDX language pack loads through the existing language registry.
2. MDX buffers receive the `mdx` filetype.
3. The native `mdx_analyzer` server starts and attaches correctly.
4. Diagnostics and completion work in representative MDX documents.
5. TypeScript SDK discovery uses the workspace installation.
6. Conform resolves dprint for MDX files.
7. `:Format` formats MDX documents correctly.
8. Embedded TypeScript formatting works through the configured dprint plugin.
9. The custom Tree-sitter parser installs and recognizes the main MDX constructs.
10. Missing external executables produce clear diagnostics.
11. Format-on-save remains disabled by default.
12. LSP formatting is not introduced as a fallback.
13. Existing Markdown and other language-pack behavior remains unaffected.
14. The Windows global installation workflow succeeds.
15. Workspace-specific dependency and formatter checks pass.

## 13. Maintenance Rules

- Keep MDX-specific behavior in `lua/langs/mdx.lua`.
- Keep parser registration in `lua/plugins/treesitter.lua`.
- Keep shared formatter behavior in the existing Conform integration.
- Keep workspace formatter configuration in `dprint.json`.
- Keep workspace TypeScript dependencies in `package.json`.
- Keep external tool installation in the Windows installer.
- Do not install external tools automatically during Neovim startup.
- Do not introduce a second formatter-resolution mechanism.
- Do not hardcode a local TypeScript SDK path.
- Do not change the parser registration API without first checking the installed nvim-treesitter version.
- Add representative fixtures when investigating parser or formatter regressions.

## 14. References

- MDX documentation: https://mdxjs.com/
- MDX language server: https://github.com/mdx-js/mdx
- MDX TypeScript plugin: https://github.com/mdx-js/mdx
- dprint: https://dprint.dev/
- dprint MDX plugin: https://github.com/dprint/dprint-plugin-mdx
- Tree-sitter MDX grammar: https://github.com/srazzak/tree-sitter-mdx
- nvim-treesitter: https://github.com/nvim-treesitter/nvim-treesitter
- nvim-lspconfig: https://github.com/neovim/nvim-lspconfig
