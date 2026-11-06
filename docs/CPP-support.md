
# C++ Support

C++ support is implemented as an independent language pack in the Neovim configuration.

It uses the native Neovim LSP client, `clangd` for language intelligence, `clang-format` for manual formatting, and Tree-sitter for syntax parsing and highlighting.

The implementation shares the clangd integration with C while keeping language-specific metadata and activation independent.

## 1. Design Principles

- Native Neovim LSP using `vim.lsp.config()` and `vim.lsp.enable()`.
- No Mason or automatic external tool installation.
- No unnecessary plugins or duplicate dependencies.
- Manual formatting without automatic format-on-save.
- Project-aware compilation through a compilation database.
- Independent C and C++ language-pack activation.
- Shared clangd configuration for C and C++.

## 2. Architecture

### Directory structure

```text
lua/
├── langs/
│   ├── c.lua
│   └── cpp.lua
│
├── lsp/
│   └── servers/
│       └── clangd.lua
│
├── config/
│   ├── languages.lua
│   ├── format.lua
│   └── keymaps.lua
│
└── plugins/
    ├── conform.lua
    └── treesitter.lua
```

### Language pack

Entry point:

```text
lua/langs/cpp.lua
```

Implementation:

```lua
-- Stage 13: C++ language pack.
-- C++ owns its formatter and Tree-sitter parser metadata.
-- The shared clangd integration owns LSP configuration and activation.

local M = {
  formatters = {
    cpp = { "clang_format" },
  },

  parser_by_filetype = {
    cpp = "cpp",
  },
}

function M.setup()
  require("lsp.servers.clangd").setup()
end

return M
```

The language pack owns its C++ formatter and parser metadata. The shared clangd module handles language-server configuration.

### Language activation

Enable C++ independently in:

```text
lua/config/languages.lua
```

```lua
packs = {
  cpp = true,
}
```

C and C++ can be enabled independently. When both are enabled, they share one clangd configuration.

## 3. Toolchain

The C++ integration uses the LLVM toolchain and MinGW-w64 GCC toolchain.

| Component | Purpose |
|---|---|
| `clangd` | C++ language server |
| `clang-format` | C++ source formatting |
| `clang` | LLVM compiler |
| `g++` | MinGW-w64 C++ compiler |
| `gcc` | MinGW-w64 C compiler |
| `clang-tidy` | Available for optional static analysis |

### Validated Windows toolchain

| Component | Version |
|---|---|
| LLVM | 23.1.5 |
| clangd | 23.1.5 |
| clang-format | 23.1.5 |
| clang-tidy | 23.1.5 |
| GCC | 16.2.0 |
| G++ | 16.2.0 |

LLVM is installed separately from Neovim. The MinGW-w64 compiler provides the GCC and G++ toolchains.

External tools must be installed and available through the system `PATH` before Neovim uses them.

No tool installation is performed by the language pack.

## 4. Language Server

### clangd

C++ uses `clangd` through the shared integration:

```text
lua/lsp/servers/clangd.lua
```

The shared module derives its supported filetypes from enabled language packs.

| Language pack | Filetype | Compiler driver |
|---|---|---|
| C | `c` | `gcc` |
| C++ | `cpp` | `g++` |

The configuration discovers available compiler executables using:

```lua
vim.fn.exepath()
```

It builds the clangd command dynamically and adds `--query-driver` only when matching compiler drivers are available.

The effective configuration uses:

```lua
vim.lsp.config("clangd", {
  cmd = cmd,
  filetypes = filetypes,
})

vim.lsp.enable("clangd")
```

A configuration guard prevents repeated setup.

### Compilation database

Project-aware compilation uses:

```text
compile_commands.json
```

clangd searches project roots using markers including:

- `.clangd`
- `.clang-tidy`
- `.clang-format`
- `compile_commands.json`
- `compile_flags.txt`
- `configure.ac`
- `.git`

A compilation database provides the compiler command and compilation arguments for each translation unit.

For reliable project diagnostics and navigation, generate a compilation database using the project's build system.

Example structure:

```json
[
  {
    "directory": "C:/projects/example/build",
    "command": "g++ -std=c++20 -I../include -c ../src/main.cpp",
    "file": "C:/projects/example/src/main.cpp"
  }
]
```

The paths and compiler arguments must match the actual project build environment.

## 5. Formatting

C++ formatting is provided by `clang-format` through Conform.

Language-pack metadata:

```lua
formatters = {
  cpp = { "clang_format" },
}
```

Formatting is manual.

Use:

```vim
:Format
```

Or the existing formatting mapping:

```text
<leader>cf
```

The formatter integration does not use LSP formatting as a fallback.

### Format-on-save

Automatic formatting remains disabled:

```lua
format_on_save = {
  enabled = false,
  timeout_ms = 500,
}
```

This keeps formatting under explicit user control.

## 6. Tree-sitter

C++ uses the `cpp` Tree-sitter parser.

Language-pack metadata:

```lua
parser_by_filetype = {
  cpp = "cpp",
}
```

The shared Tree-sitter integration:

1. Collects parser mappings from enabled language packs.
2. Checks whether the parser is already installed.
3. Installs missing parsers asynchronously.
4. Starts native Tree-sitter highlighting when the parser becomes available.
5. Avoids duplicate installation requests.

No separate C++ Tree-sitter plugin is required.

## 7. Validated Features

The C++ integration was tested on Windows using Neovim 0.12.6.

| Feature | Result |
|---|---|
| clangd executable discovery | Passed |
| Native clangd attachment | Passed |
| C++ filetype detection | Passed |
| C++ diagnostics | Passed |
| Go to definition | Passed |
| Find references | Passed |
| Hover documentation | Passed |
| Completion | Passed |
| Signature help | Passed |
| Symbol rename | Passed |
| Document symbols | Passed |
| Workspace symbols | Passed |
| clang-format executable | Passed |
| Manual Conform formatting | Passed |
| Format-on-save disabled | Passed |
| Tree-sitter parser discovery | Passed |
| Native Tree-sitter highlighting | Passed |
| C++ syntax-tree parsing | Passed |
| Shared C/C++ clangd configuration | Passed |

### Validation environment

Temporary validation workspace:

```text
%TEMP%\nvim-cpp-validation
```

The tests covered a C++ source file containing:

- A function declaration and definition.
- A function call.
- Standard library usage.
- A deliberately undefined identifier for diagnostics.
- Symbol references and rename operations.
- Workspace symbol indexing.

The compilation database was also validated as a JSON array, including the single-entry case.

## 8. Current Limitations

The following features are not part of the validated baseline:

- Automatic format-on-save.
- Automatic toolchain installation.
- clang-tidy integration.
- Dedicated source/header switching.
- Custom C++ build commands.
- Dedicated C++ debugging configuration.

Some of these capabilities can be considered separately without expanding the baseline unnecessarily.

## 9. Future Considerations

Potential future improvements should be evaluated independently:

- clang-tidy diagnostics and static analysis.
- Source/header navigation through clangd.
- Build-system integration for CMake and other project generators.
- C++ debugging through the existing DAP architecture.
- Additional compiler support where required.

Do not introduce another language server or formatter without a demonstrated requirement.

## 10. References

- [clangd documentation](https://clangd.llvm.org/)
- [clangd configuration](https://clangd.llvm.org/config)
- [clangd compilation database](https://clangd.llvm.org/installation#compile_commandsjson)
- [clang-format documentation](https://clang.llvm.org/docs/ClangFormat.html)
- [LLVM project](https://github.com/llvm/llvm-project)
- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)
- [Conform.nvim](https://github.com/stevearc/conform.nvim)
