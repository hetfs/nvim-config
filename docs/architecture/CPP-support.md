# Stage 13: C++ Language Support

## 1. Purpose

This document defines the architecture, dependencies, implementation decisions, and validation requirements for C++ language support in the Neovim configuration.

C++ is an independent Stage 13 language pack. It uses the native Neovim LSP architecture, shares clangd integration with C, and maintains independent language metadata and activation.

The implementation follows these principles:

- Native Neovim LSP using `vim.lsp.config()` and `vim.lsp.enable()`.
- No Mason or automatic external tool installation.
- No unnecessary plugins or duplicate dependencies.
- Manual formatting without automatic format-on-save.
- Project-aware compilation through a compilation database.
- Independent C and C++ language-pack activation.
- Shared clangd configuration for C and C++.
- Shared CMake build and execution infrastructure.
- Buffer-local language workflow mappings.
- Explicit external-tool installation and validation.

## 2. Architecture

### Directory structure

The relevant implementation structure is:

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
│   ├── cmake.lua
│   ├── languages.lua
│   ├── format.lua
│   ├── keymaps.lua
│   └── autocmds.lua
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

Example:

```lua
packs = {
    cpp = true,
}
```

C and C++ can be enabled independently. When both are enabled, they share one clangd configuration.

### Shared CMake integration

The CMake workflow is implemented in:

```text
lua/config/cmake.lua
```

It provides project discovery, build, and executable execution for both C and C++.

The root `init.lua` initializes it directly:

```lua
require("config.cmake").setup()
```

This initialization registers `:CMakeBuild` and `:CMakeRun` once during startup.

## 3. Toolchain

**Approved compiler toolchain: WinLibs GCC/G++ with LLVM tooling.**

The C++ integration uses the WinLibs MinGW-w64 POSIX UCRT x64 toolchain for compilation and LLVM tools for language intelligence and formatting.

| Component | Purpose |
|---|---|
| `clangd` | C++ language server |
| `clang-format` | C++ source formatting |
| `clang` | LLVM compiler |
| `g++` | MinGW-w64 C++ compiler |
| `gcc` | MinGW-w64 C compiler |
| `clang-tidy` | Optional static analysis |

### Validated Windows toolchain

| Component | Version |
|---|---|
| LLVM | 23.1.5 |
| clangd | 23.1.5 |
| clang-format | 23.1.5 |
| clang-tidy | 23.1.5 |
| GCC | 16.2.0 |
| G++ | 16.2.0 |
| CMake | 4.4.4 |
| Ninja | 1.13.2 |

LLVM is installed separately from Neovim. The MinGW-w64 compiler provides the GCC and G++ toolchains.

The LLVM clang executable targets MSVC in the validated environment. It must not be confused with the WinLibs GCC/G++ toolchain.

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

The shared module must preserve the existing clangd server definition, including its root markers and supported project metadata.

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

Example:

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

### CMake compilation database generation

CMake can generate the compilation database:

```powershell
cmake -S . -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
```

The generated database is normally located at:

```text
build/compile_commands.json
```

clangd must be able to locate the database in the appropriate build directory.

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

The formatter must respect project-level configuration when available:

```text
.clang-format
```

C and C++ share the same formatter executable and configuration mechanism.

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

Parser installation belongs to the existing language-pack and Tree-sitter lifecycle.

No separate C++ Tree-sitter plugin or manual parser installation workflow is required.

## 7. CMake Build and Execution

C++ uses the shared CMake integration:

```text
lua/config/cmake.lua
```

The integration supports C and C++ projects without duplicating build logic in individual language packs.

### Project discovery

The module locates the outermost ancestor containing:

```text
CMakeLists.txt
```

It uses the current source buffer to identify the project root.

It rejects invalid buffers, unnamed buffers, and buffers without a valid file path.

### Build command

The implemented command is:

```vim
:CMakeBuild
```

The C++ buffer-local mapping is:

```text
<leader>cb
```

The command:

1. Resolves the CMake project root.
2. Checks for the project's `build/` directory.
3. Executes the CMake build.
4. Uses the project root as the process working directory.
5. Captures standard output and standard error.
6. Parses supported compiler diagnostics into quickfix entries.
7. Reports build success or failure.

The build command is equivalent to:

```powershell
cmake --build build
```

The integration does not configure projects automatically.

If the build directory does not exist, configure the project explicitly:

```powershell
cmake -S . -B build
```

### Executable command

The implemented command is:

```vim
:CMakeRun
```

The C++ buffer-local mapping is:

```text
<leader>cr
```

The command:

1. Resolves the project root.
2. Prompts for an executable path.
3. Accepts project-relative or absolute paths.
4. Rejects directories and non-executable files.
5. Opens a bottom terminal split.
6. Executes the selected program with the project root as its working directory.
7. Cleans up the terminal window and buffer if process startup fails.

The executable is selected explicitly by the user.

The integration does not guess the target executable or automatically run the most recently built target.

### Build-system scope

CMake is the approved initial build integration.

Make and Meson are deferred.

CMake does not replace the project's compiler configuration, build configuration, or compilation database.

## 8. Source and Header Navigation

C++ supports source/header navigation through clangd's `textDocument/switchSourceHeader` extension.

Example relationship:

```text
main.cpp
main.hpp
```

The implemented mapping is:

```text
<leader>ch
```

The mapping is registered through the centralized keymap module and is buffer-local.

The implementation:

- Locates the clangd client attached to the current buffer.
- Checks support for the source/header switching method.
- Sends the clangd extension request.
- Handles rejected requests and callback errors.
- Handles missing matching files.
- Opens the returned file in the original window.
- Avoids switching if the original buffer or window is no longer valid.

The mapping is registered for C and C++ buffers through the existing FileType autocmd infrastructure.

No additional navigation plugin is required.

## 9. Validated Features

The C++ integration was tested on Windows using Neovim 0.12.6.

### 9.1 Previously validated language-server features

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

### 9.2 Previously validated formatting and syntax features

| Feature | Result |
|---|---|
| clang-format executable | Passed |
| Manual Conform formatting | Passed |
| Format-on-save disabled | Passed |
| Tree-sitter parser discovery | Passed |
| Native Tree-sitter highlighting | Passed |
| C++ syntax-tree parsing | Passed |
| Shared C/C++ clangd configuration | Passed |

These results belong to the earlier C++ validation workspace and should be retained as historical implementation evidence.

### 9.3 Real-project workflow validation

The C++ integration was additionally tested using a real Windows CMake project.

Validation environment:

| Component | Version |
|---|---|
| Neovim | 0.12.6 |
| CMake | 4.4.4 |
| Ninja | 1.13.2 |
| GCC | 16.2.0 |
| G++ | 16.2.0 |
| Platform | Windows |

The test used the temporary project:

```text
%TEMP%\nvim-config-cmake-smoke
```

Results:

| Workflow | Mapping | Result |
|---|---|---|
| Build CMake project | `<leader>cb` | Passed |
| Run compiled executable | `<leader>cr` | Passed |
| Switch source to header | `<leader>ch` | Passed |
| Switch header to source | `<leader>ch` | Passed |

The executable produced:

```text
CMake + Ninja + WinLibs: OK
```

These tests confirm that the CMake workflows and clangd source/header switching operate through the running Neovim configuration.

### 9.4 Automated C/C++ and CMake tests

Seven test suites passed:

| Test suite | Checks passed |
|---|---:|
| C/C++ keymaps | 7 |
| C/C++ autocmds | 7 |
| clangd source/header switching | 15 |
| CMake project roots | 4 |
| CMake build command | 3 |
| CMake build execution | 6 |
| CMake executable execution | 7 |
| **Total** | **49** |

Additional quality checks:

- [x] Lua syntax validation: 64 Lua files passed.
- [x] Targeted StyLua validation for the C/C++ implementation and selected tests.
- [x] `git diff --check` completed cleanly.

**Repository-wide formatting qualification:** `stylua --check .` reported existing formatting differences in unrelated configuration, plugin, Rust test, and other test files. The CMake executable test file also had an outstanding formatting difference and was excluded from the targeted StyLua command.

The repository-wide formatting check must be reconciled separately. The targeted StyLua pass does not establish that the entire repository passes formatting validation.

## 10. Current Limitations and Remaining Validation

The following features are not part of the validated baseline:

- Automatic format-on-save.
- Automatic toolchain installation.
- Dedicated clang-tidy integration.
- Automatic compilation database generation.
- Automatic project configuration.
- Automatic build execution.
- Dedicated C++ debugging configuration.
- Dedicated C++ testing frameworks.

The following additional validation remains outstanding:

- [ ] Reconfirm the C++ LSP and Tree-sitter tests in the current integrated configuration.
- [ ] Validate project include directories through the compilation database.
- [ ] Validate project preprocessor definitions.
- [ ] Validate language-standard flags.
- [ ] Validate CMake-generated compilation database discovery.
- [ ] Validate clangd behavior without a compilation database.
- [ ] Validate clang-tidy against a real C++ project.
- [ ] Complete C++ header classification checks.
- [ ] Review external-tool installation-script integration.
- [ ] Reconcile repository-wide StyLua differences.
- [ ] Complete final documentation and smoke-test review.

These checks must be completed or explicitly deferred before claiming full Stage 13 C++ validation.

## 11. Future Considerations

Potential future improvements should be evaluated independently:

- clang-tidy diagnostics and static analysis.
- Additional compilation database discovery workflows.
- Make and Meson build-system support.
- C++ debugging through the existing DAP architecture.
- Additional compiler support where required.

Do not introduce another language server, formatter, or project-management module without a demonstrated requirement.

The existing CMake and clangd integrations should remain the default shared infrastructure.

## 12. References

- [clangd documentation](https://clangd.llvm.org/)
- [clangd configuration](https://clangd.llvm.org/config)
- [clangd compilation database](https://clangd.llvm.org/installation#compile_commandsjson)
- [clang-format documentation](https://clang.llvm.org/docs/ClangFormat.html)
- [LLVM project](https://github.com/llvm/llvm-project)
- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)
- [Conform.nvim](https://github.com/stevearc/conform.nvim)
- [CMake documentation](https://cmake.org/documentation/)
- [Ninja documentation](https://ninja-build.org/manual.html)
