# Stage 13: C Language Support

## 1. Purpose

This document defines the architecture, dependencies, implementation decisions, and validation requirements for C language support in the Neovim configuration.

C is an independent Stage 13 language pack. It uses the existing native Neovim LSP architecture and shares infrastructure with the independently enabled C++ language pack.

The implementation follows these principles:

- Native Neovim LSP through `vim.lsp.config()` and `vim.lsp.enable()`.
- No Mason or automatic tool installation.
- No unnecessary plugins or duplicate dependencies.
- Manual formatting without automatic format-on-save.
- Project-aware compilation through a compilation database.
- Explicit external-tool installation and validation.
- Independent C and C++ language packs with shared infrastructure.
- Explicit CMake build and execution workflows.
- Buffer-local language keymaps with centralized ownership.

## 2. Architecture

### Directory structure

The C language pack is implemented at:

```text
lua/langs/c.lua
```

The C++ language pack is implemented independently at:

```text
lua/langs/cpp.lua
```

The shared clangd integration is:

```text
lua/lsp/servers/clangd.lua
```

The CMake workflow is implemented at:

```text
lua/config/cmake.lua
```

The relevant configuration structure is:

```text
lua/
├── config/
│   ├── cmake.lua
│   ├── format.lua
│   ├── keymaps.lua
│   ├── languages.lua
│   └── autocmds.lua
│
├── langs/
│   ├── c.lua
│   └── cpp.lua
│
├── lsp/
│   └── servers/
│       └── clangd.lua
│
└── plugins/
    ├── lsp.lua
    ├── treesitter.lua
    └── conform.lua
```

This structure describes the relevant ownership boundaries. Existing modules must be inspected before adding new files or functionality.

### Architectural responsibilities

| Component | Responsibility |
|---|---|
| `langs/c.lua` | C-specific configuration and metadata |
| `langs/cpp.lua` | C++-specific configuration and metadata |
| `lsp/servers/clangd.lua` | Shared clangd configuration |
| `config/cmake.lua` | CMake project discovery, build, and execution |
| `config/keymaps.lua` | C/C++ and shared LSP keymaps |
| `config/autocmds.lua` | Buffer-local language keymap registration |
| Treesitter | C and C++ parser integration |
| Conform | clang-format integration |
| Native Neovim LSP | Language-server lifecycle and communication |
| WinLibs | GCC and G++ toolchain |
| Project build system | Compiler flags and compilation database |

C and C++ remain independently enabled while sharing clangd and compatible external tools.

## 3. Language Server

**Approved language server: clangd**

C uses clangd through Neovim's native LSP client.

No additional LSP client plugin is required.

### Responsibilities

clangd provides:

- Code completion.
- Diagnostics.
- Go to definition and declaration.
- Find references.
- Hover documentation.
- Rename symbol.
- Document symbols.
- Workspace symbols.
- Code actions.
- Semantic analysis.
- Inlay hints.
- Header and source-file navigation.

### Native LSP integration

The existing native Neovim LSP architecture owns:

- Server configuration.
- Server activation.
- Client attachment.
- LSP capabilities.
- Buffer-local mappings.
- Diagnostics.
- Inlay hints.

The C language pack must not create another LSP client or duplicate shared server configuration.

### Server definition and activation

`nvim-lspconfig` supplies the clangd server definition. The shared integration configures the executable and enabled language filetypes through the native Neovim LSP API.

The server definition must be available before language-pack activation so its capabilities and root markers are preserved.

The existing clangd definition provides these project-root markers:

```lua
{
  ".clangd",
  ".clang-tidy",
  ".clang-format",
  "compile_commands.json",
  "compile_flags.txt",
  "configure.ac",
  ".git",
}
```

The shared clangd integration must preserve these defaults when applying its configuration.

### Executable

```text
clangd
```

The executable must be installed explicitly and available through the system PATH.

Mason must not install or manage clangd.

## 4. Compilation Database

**Primary compilation metadata: `compile_commands.json`**

A compilation database provides clangd with the actual compilation context of individual source files.

It can contain:

- Compiler executable.
- Compiler arguments.
- Include directories.
- Preprocessor definitions.
- Language-standard flags.
- Target architecture.
- Other compilation options.

### Configuration policy

clangd should discover and use the project's compilation database whenever available.

The language pack must not hardcode project-specific compiler flags, include paths, or preprocessor definitions.

### Supported discovery mechanisms

| Mechanism | Purpose |
|---|---|
| `compile_commands.json` | Primary compilation database |
| `compile_flags.txt` | Fallback for simple projects |
| `.clangd` | Project-specific clangd configuration |

### CMake integration

CMake can generate a compilation database:

```powershell
cmake -S . -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
```

The generated file is normally located at:

```text
build/compile_commands.json
```

clangd must be able to locate the database in the appropriate build directory.

### Bear integration

Bear can generate a compilation database by intercepting compatible build-system compiler invocations.

Example:

```powershell
bear -- make
```

Bear is optional and is not a mandatory C baseline dependency.

### Fallback policy

When no compilation database is available, clangd may use its fallback configuration.

Fallback behavior must remain conservative. It must not replace proper project compilation metadata.

## 5. Compiler and Toolchain

**Approved compiler: GCC from WinLibs**

C reuses the existing WinLibs GCC/MinGW-w64 POSIX UCRT x64 toolchain.

### Tool inventory

| Tool | Executable | Purpose |
|---|---|---|
| GCC | `gcc.exe` | C compilation |
| G++ | `g++.exe` | C++ compilation |
| GNU Binutils | `ar.exe` | Static library archiving |
| GNU Binutils | `ld.exe` | Linking |
| GNU Binutils | `objdump.exe` | Object-file inspection |

The actual required executable inventory must be verified against the installed WinLibs distribution.

### Toolchain policy

- Reuse the existing WinLibs installation.
- Do not introduce another default C compiler.
- Do not install MSVC as part of the baseline.
- Do not install a separate compiler solely for clangd.
- Keep compilation independent of the language-server implementation.
- Share the toolchain between C and C++ packs.

clangd provides language intelligence. GCC and G++ perform compilation.

## 6. Treesitter

**Approved parsers: `c` and `cpp`**

The C language pack contributes the following parser metadata:

```lua
parser_by_filetype = {
  c = "c",
}
```

The C++ language pack independently contributes:

```lua
parser_by_filetype = {
  cpp = "cpp",
}
```

The existing central Treesitter configuration owns parser discovery, installation, and setup.

When an enabled language pack declares a parser, the existing integration must handle its installation lifecycle.

The language packs must not install or configure separate Treesitter instances.

## 7. Formatting

**Approved formatter: clang-format**

Formatting is integrated through the existing Conform configuration.

| Property | Decision |
|---|---|
| Formatter | `clang-format` |
| Integration | Conform |
| Command | `:Format` |
| Keymap | `<leader>cf` |
| Format on save | Disabled |
| LSP formatting fallback | Disabled |

Formatting remains manually triggered.

The formatter must respect project-level configuration when available:

```text
.clang-format
```

clangd provides language intelligence. clang-format provides source formatting. These responsibilities must remain separate.

C and C++ share the same formatter executable and configuration mechanism.

## 8. Static Analysis

**Approved analysis tool: clang-tidy**

clang-tidy provides additional static analysis for C and C++ projects.

It can identify:

- Potential programming errors.
- Suspicious code patterns.
- Maintainability issues.
- Performance concerns.
- Modernization opportunities.

### Integration policy

clang-tidy may be integrated through clangd's supported configuration.

The project will not introduce `nvim-lint` solely for C analysis.

Project-specific analysis rules belong in:

```text
.clang-tidy
```

Static-analysis checks must use the project's compilation context.

clang-tidy is an approved optional component. Installation and activation remain explicit.

## 9. Filetypes and Headers

The C language pack must recognize C source files.

| Extension | Expected filetype |
|---|---|
| `.c` | `c` |
| `.h` | Project-dependent C or C++ classification |

Header files require special attention because `.h` can represent either C or C++ headers.

The implementation must not blindly force every `.h` file into C mode.

clangd should use project metadata and header-inference mechanisms where appropriate.

The C++ language pack must recognize its own source and header filetypes, including `.cpp`, `.cc`, `.cxx`, `.hpp`, `.hh`, and `.hxx`, as applicable to the existing configuration.

C++ header handling must remain compatible with the C pack.

## 10. Source and Header Navigation

The C/C++ workflow supports navigation between source and header files through clangd's source/header switching extension.

Example relationships:

```text
main.c
main.h
```

```text
main.cpp
main.hpp
```

The implemented mapping is:

```text
<leader>ch
```

### Implementation

The mapping is registered through the existing centralized keymap module.

The implementation:

- Locates the clangd client attached to the current buffer.
- Checks support for the source/header switching method.
- Sends `textDocument/switchSourceHeader`.
- Handles rejected requests and callback errors.
- Handles missing matching files.
- Opens the returned file in the original window.
- Avoids switching if the original buffer or window is no longer valid.

The mapping is buffer-local and registered for C and C++ buffers through the existing FileType autocmd infrastructure.

No additional navigation plugin is required.

## 11. CMake Build and Execution

**Implemented integration: `lua/config/cmake.lua`**

CMake provides a shared build and execution workflow for C and C++ projects.

The integration is independent of the individual language packs and uses the existing project structure rather than introducing a separate project-root module.

### Project discovery

The module locates the outermost ancestor containing:

```text
CMakeLists.txt
```

It uses the current file buffer to identify the project.

It rejects invalid buffers, unnamed buffers, and buffers without a valid file path.

### Build workflow

The implemented command is:

```vim
:CMakeBuild
```

The C/C++ buffer-local mapping is:

```text
<leader>cb
```

The command:

1. Resolves the project root from the current buffer.
2. Checks for the project's `build/` directory.
3. Builds using the CMake build command.
4. Runs the process with the project root as its working directory.
5. Captures standard output and standard error.
6. Parses supported compiler diagnostics into quickfix entries.
7. Reports build success or failure.

The build command is equivalent to:

```powershell
cmake --build build
```

The integration does not configure projects automatically.

If the build directory does not exist, the user must configure the project explicitly:

```powershell
cmake -S . -B build
```

### Execution workflow

The implemented command is:

```vim
:CMakeRun
```

The C/C++ buffer-local mapping is:

```text
<leader>cr
```

The command:

1. Resolves the project root.
2. Prompts for an executable path.
3. Accepts project-relative or absolute paths.
4. Rejects directories and non-executable files.
5. Opens a bottom terminal split.
6. Executes the program with the project root as its working directory.
7. Cleans up the terminal window and buffer if process startup fails.

The executable is selected explicitly by the user.

The integration does not guess the target executable or automatically run the most recently built target.

### Command initialization

The CMake module defines `M.setup()`. Defining this function does not register commands until it is called.

The root `init.lua` initializes the module directly:

```lua
require("config.cmake").setup()
```

This call is made once during startup alongside the other general configuration modules.

The commands are available after initialization, independently of whether a C or C++ buffer is currently open.

### Build-system scope

CMake is the approved initial build integration.

Make and Meson are deferred.

The CMake integration does not replace the project's build configuration, compiler flags, or compilation database.

## 12. Compilation Database Management

A proposed command is:

```vim
:CCompileDb
```

Its purpose would be to help locate or select a compilation database when automatic discovery is insufficient.

This command remains **proposed, not implemented or approved for the baseline**.

If retained, it must:

- Reuse existing project-root infrastructure.
- Avoid automatic database generation.
- Avoid installing build tools.
- Avoid modifying compiler flags.
- Avoid silently overriding valid project metadata.
- Require explicit user action when selecting a database.

Do not introduce a new root-management module solely to support this proposal.

## 13. External Tool Inventory

| Tool | Category | Status |
|---|---|---|
| WinLibs GCC | Compiler | Approved and installed |
| WinLibs G++ | Compiler | Approved and installed |
| clangd | Language server | Approved and installed |
| clang-format | Formatter | Approved and installed |
| clang-tidy | Static analysis | Approved and installed |
| CMake | Build integration | Supported and installed |
| Ninja | Build generator | Verified in real-project validation |
| Bear | Compilation database generation | Optional |

External tools must be managed through the existing modular Windows installation infrastructure.

The C installation script must install or validate only the dependencies it owns.

Shared dependencies must not be installed repeatedly by C and C++ packs.

For example:

- GCC and G++ belong to the shared WinLibs toolchain.
- clangd is shared between C and C++.
- clang-format is shared between C and C++.
- clang-tidy is shared between C and C++.
- CMake and Ninja are shared build dependencies where required.

No Mason installation or automatic startup installation is permitted.

## 14. Configuration Ownership

| Responsibility | Owner |
|---|---|
| C filetypes | C language pack |
| C++ filetypes | C++ language pack |
| C parser metadata | C language pack and central Treesitter configuration |
| C++ parser metadata | C++ language pack and central Treesitter configuration |
| Language-server association | Shared clangd configuration |
| LSP client lifecycle | Native Neovim LSP |
| LSP keymaps | Centralized LSP keymap infrastructure |
| C/C++ workflow keymaps | Centralized keymap module |
| FileType mapping registration | `config.autocmds` |
| CMake commands | `config.cmake` |
| CMake initialization | Root `init.lua` |
| Formatting | Conform |
| Formatting rules | `.clang-format` |
| Static-analysis rules | `.clang-tidy` |
| Compiler configuration | Project build system |
| Compilation database | Project build system |
| External dependencies | Modular installation scripts |

This separation prevents duplicate configuration and supports independent language-pack activation.

## 15. Validation Requirements and Current Status

Validation distinguishes between executable availability, configuration correctness, automated tests, and actual editor behavior.

### 15.1 External tools

Verified versions:

| Tool | Verified version |
|---|---|
| GCC | 16.2.0 |
| G++ | 16.2.0 |
| clangd | 23.1.5 |
| clang-format | 23.1.5 |
| clang-tidy | 23.1.5 |
| CMake | 4.4.4 |
| Ninja | 1.13.2 |

The WinLibs compiler is the MinGW-w64 POSIX UCRT x64 toolchain.

The installed LLVM clang executable targets MSVC. It must not be confused with the WinLibs GCC toolchain.

### 15.2 clangd and native LSP validation

The following C language-server checks have passed:

- [x] clangd executable discovery.
- [x] C-only filetype configuration.
- [x] GCC compiler query-driver configuration.
- [x] Native Neovim LSP attachment.
- [x] C diagnostics.
- [x] Go to definition.
- [x] Find references.
- [x] Hover documentation.
- [x] Completion request.
- [x] Signature help.
- [x] Rename symbol.
- [x] Document symbols.

The find-references and rename tests accounted for Windows short-path and long-path aliases when comparing returned locations.

Workspace Symbols:

- [ ] End-to-end workspace-symbol request.

The initial test returned an empty result because the headless test did not load the `nvim-lspconfig` server definition before activating the language pack.

The installed definition and merged configuration were subsequently inspected. The required root markers, including `compile_commands.json`, were present after loading the definition.

The end-to-end workspace-symbol test must be rerun with the corrected initialization order before it is marked complete.

### 15.3 Compilation database

Previously validated:

- [x] Created a temporary `compile_commands.json`.
- [x] clangd loaded the compilation database.
- [x] clangd executed GCC through the configured query driver.
- [x] MinGW-w64 system include directories were discovered.
- [x] clangd recognized the MinGW target.

Remaining:

- [ ] Validate project include directories.
- [ ] Validate project preprocessor definitions.
- [ ] Validate language-standard flags.
- [ ] Validate CMake-generated database discovery.
- [ ] Validate behavior without a compilation database.

### 15.4 Treesitter

- [ ] Confirm the C parser is installed.
- [ ] Confirm C buffers are recognized.
- [ ] Confirm syntax highlighting.
- [ ] Confirm no parser initialization errors.
- [ ] Confirm the C++ parser is installed and operational.

Parser installation must use the existing language-pack and Treesitter lifecycle. Manual parser installation is not the normal workflow.

### 15.5 Formatting

- [ ] Confirm Conform recognizes clang-format.
- [ ] Validate `:Format`.
- [ ] Validate `<leader>cf`.
- [ ] Confirm `.clang-format` is respected.
- [ ] Confirm format-on-save remains disabled.
- [ ] Confirm LSP formatting fallback remains disabled.

### 15.6 Static analysis

- [ ] Validate clang-tidy against the temporary C project.
- [ ] Validate compilation database usage.
- [ ] Validate project-specific `.clang-tidy` rules.

### 15.7 Header behavior

- [ ] Validate `.c` filetype detection.
- [ ] Validate C header handling.
- [ ] Validate C++ header handling.
- [ ] Confirm headers are not incorrectly forced into C mode.

### 15.8 CMake build and execution

Automated CMake tests:

- [x] Outermost CMake project-root detection.
- [x] Invalid and unnamed buffer handling.
- [x] Build command construction.
- [x] Build-directory validation.
- [x] Build process execution.
- [x] Build process failure reporting.
- [x] Build output parsing.
- [x] Executable prompt cancellation.
- [x] Empty executable input handling.
- [x] Executable path resolution.
- [x] Directory and missing executable rejection.
- [x] Terminal startup failure cleanup.

Real Windows project validation:

- [x] CMake 4.4.4 detected.
- [x] Ninja 1.13.2 detected.
- [x] WinLibs GCC/G++ 16.2.0 detected.
- [x] CMake project configured.
- [x] Build executed successfully through `<leader>cb`.
- [x] Executable launched successfully through `<leader>cr`.
- [x] Executable output confirmed: `CMake + Ninja + WinLibs: OK`.

The real-project test confirms the CMake build and execution mappings work through the running Neovim configuration.

### 15.9 C/C++ keymaps and source/header navigation

Automated checks:

- [x] C/C++ build mapping registered buffer-locally.
- [x] C/C++ run mapping registered buffer-locally.
- [x] C/C++ source/header mapping registered buffer-locally.
- [x] C/C++ mappings are not registered globally.
- [x] Rust mappings remain buffer-local.
- [x] C/C++ and Rust mappings remain isolated.
- [x] Existing global Format mapping remains available.
- [x] C FileType registers C/C++ mappings.
- [x] C++ FileType registers C/C++ mappings.
- [x] Unrelated filetypes do not receive C/C++ mappings.
- [x] clangd source/header request uses the expected extension method.
- [x] Request and callback errors are handled.
- [x] Missing matching files are handled.
- [x] Successful switching opens the returned file in the original window.

Real-project validation:

- [x] `<leader>ch` switches from source to header.
- [x] `<leader>ch` switches from header to source.

### 15.10 Automated quality checks

The seven C/C++ and CMake test suites passed:

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

Additional checks:

- [x] Lua syntax validation: 64 Lua files passed.
- [x] Targeted StyLua validation for the C/C++ implementation and selected tests.
- [x] `git diff --check` completed cleanly.

**Repository-wide formatting qualification:** `stylua --check .` reported existing formatting differences in unrelated configuration, plugin, Rust test, and other test files. These files were not broadly reformatted as part of C/C++ integration. The CMake executable test file also had an outstanding formatting difference and was excluded from the targeted StyLua command.

The repository-wide formatting check must be reconciled separately. Do not treat the targeted StyLua pass as proof that the entire repository passes formatting validation.

### 15.11 Remaining integration work

- [ ] Rerun end-to-end workspace-symbol validation with the corrected server initialization order.
- [ ] Complete remaining compilation database checks.
- [ ] Validate Treesitter parser behavior.
- [ ] Validate Conform formatting.
- [ ] Validate clang-tidy analysis.
- [ ] Complete C and C++ header classification checks.
- [ ] Review installation-script integration.
- [ ] Complete documentation review.
- [ ] Reconcile repository-wide StyLua differences.
- [ ] Run the final smoke suite.
- [ ] Commit and push after implementation and validation are complete.

## 16. Scope Exclusions

The baseline C language pack does not introduce:

- MSVC toolchain installation.
- Mason package management.
- A separate C LSP client.
- A separate Treesitter plugin.
- Automatic format-on-save.
- Automatic LSP formatting fallback.
- `nvim-lint` integration.
- Automatic compilation database generation.
- Automatic build execution.
- Dedicated C debugging infrastructure.
- Dedicated C testing frameworks.
- Objective-C support.
- CUDA support.

CMake integration provides explicit build and execution commands. It does not automatically configure, build, or execute projects.

These exclusions keep Stage 13 focused on language support.

## 17. Relationship with C++ Support

C and C++ are independent language packs that share appropriate infrastructure.

Both language packs are implemented.

| Component | C | C++ |
|---|---|---|
| Language pack | `c.lua` | `cpp.lua` |
| Language server | clangd | clangd |
| LSP client | Native Neovim | Native Neovim |
| Treesitter | `c` | `cpp` |
| Formatter | clang-format | clang-format |
| Static analysis | clang-tidy | clang-tidy |
| Compiler | GCC | G++ |
| Toolchain | WinLibs | WinLibs |
| Compilation database | `compile_commands.json` | `compile_commands.json` |
| Build integration | Shared CMake module | Shared CMake module |
| Build mapping | `<leader>cb` | `<leader>cb` |
| Run mapping | `<leader>cr` | `<leader>cr` |
| Source/header mapping | `<leader>ch` | `<leader>ch` |

### Shared infrastructure principles

1. C and C++ retain separate language packs.
2. clangd is configured once and shared.
3. clang-format and clang-tidy are shared executables.
4. GCC and G++ belong to the same WinLibs toolchain.
5. Each language owns its filetypes and parser metadata.
6. Each language pack activates only its own filetypes.
7. Project compilation databases determine compiler flags and include paths.
8. Shared configuration must not assume that both languages are enabled.
9. Shared dependencies must not be installed twice.
10. C++ support must not regress existing C functionality.
11. CMake build and execution workflows are shared rather than duplicated.
12. C/C++ workflow mappings remain buffer-local.

## 18. Completion Criteria

C support is implemented, and its core C/C++ integration has passed automated and real-project workflow validation.

The following implementation criteria are complete:

- [x] C language pack implemented.
- [x] C++ language pack implemented independently.
- [x] clangd integrated through native Neovim LSP.
- [x] Shared clangd configuration supports independent C and C++ activation.
- [x] WinLibs GCC verified.
- [x] WinLibs G++ verified.
- [x] clangd verified.
- [x] clang-format verified as an installed executable.
- [x] clang-tidy verified as an installed executable.
- [x] CMake build and execution integration implemented.
- [x] CMake initialization registered in root `init.lua`.
- [x] C/C++ buffer-local keymaps implemented.
- [x] Automated C/C++ and CMake tests passed: 49/49.
- [x] Real CMake build passed.
- [x] Real CMake executable execution passed.
- [x] Real clangd source/header switching passed.
- [x] Lua syntax validation passed.
- [x] Targeted StyLua validation passed.
- [x] `git diff --check` passed.

The following validation criteria remain outstanding:

- [ ] Workspace Symbols validated end to end.
- [ ] C and C++ Treesitter parser behavior validated.
- [ ] Conform formatting validated.
- [ ] clang-tidy analysis validated.
- [ ] Remaining compilation database behavior validated.
- [ ] C and C++ header classification fully validated.
- [ ] Installation-script integration reviewed.
- [ ] Repository-wide formatting differences reconciled.
- [ ] Final documentation and smoke-test review completed.
- [ ] Changes committed and pushed.

Do not mark the entire C language-support workstream complete until the remaining validation criteria have been addressed or explicitly deferred.

## 19. Final Architecture Decision

C support uses a native-first, project-aware development architecture.

Approved baseline:

- Language server: clangd.
- LSP client: Native Neovim.
- Parser: Treesitter C.
- Formatter: clang-format through Conform.
- Static analysis: clang-tidy.
- Compiler: GCC from WinLibs.
- Compilation metadata: `compile_commands.json`.
- Build integration: CMake.
- Build and execution commands: `:CMakeBuild` and `:CMakeRun`.
- Source/header navigation: clangd extension through `<leader>ch`.
- Installation: Explicit Windows installation scripts.

C remains an independent language pack while reusing shared C/C++ infrastructure.

The project defines how its code is compiled. The language pack provides language-specific integration without embedding project build assumptions.

**Guiding principle:**

> Keep language configuration independent. Share infrastructure where it makes architectural sense. Let the project define how its code is compiled.
