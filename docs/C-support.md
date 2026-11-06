# Stage 13: C Language Support

## 1. Purpose

This document defines the architecture, dependencies, implementation decisions, and validation requirements for C language support in the Neovim configuration.

C is an independent Stage 13 language pack. It uses the existing native Neovim LSP architecture and reuses shared infrastructure where appropriate.

The implementation follows these principles:

- Native Neovim LSP through `vim.lsp.config()` and `vim.lsp.enable()`.
- No Mason or automatic tool installation.
- No unnecessary plugins or duplicate dependencies.
- Manual formatting without automatic format-on-save.
- Project-aware compilation through a compilation database.
- Explicit external-tool installation and validation.
- Independent C and C++ language packs with shared infrastructure.

## 2. Architecture

### Directory structure

The C language pack is implemented at:

```text
lua/langs/c.lua
```

The shared clangd integration is:

```text
lua/lsp/servers/clangd.lua
```

The existing infrastructure also includes:

```text
lua/
├── config/
│   ├── format.lua
│   └── languages.lua
│
├── langs/
│   ├── c.lua
│   └── cpp.lua             # Planned independent C++ pack
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
| `langs/cpp.lua` | Independent C++ configuration |
| `lsp/servers/clangd.lua` | Shared clangd configuration |
| Treesitter | C and C++ parser integration |
| Conform | clang-format integration |
| Native Neovim LSP | Language-server lifecycle and communication |
| WinLibs | GCC and G++ toolchain |
| Project build system | Compiler flags and compilation database |

C and C++ must remain independently enabled while sharing clangd and compatible external tools.

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

`nvim-lspconfig` supplies the clangd server definition. The shared integration configures the executable and enabled language filetypes through the native API.

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

clangd provides language intelligence. GCC performs compilation.

## 6. Treesitter

**Approved parser: `c`**

The C language pack contributes the following parser metadata:

```lua
parser_by_filetype = {
  c = "c",
}
```

The existing central Treesitter configuration owns parser installation and setup.

The C language pack must not install or configure a separate Treesitter instance.

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

## 8. Static Analysis

**Approved analysis tool: clang-tidy**

clang-tidy provides additional static analysis for C projects.

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

C++ header handling must be validated separately when the C++ pack is implemented.

## 10. Source and Header Navigation

The development workflow should support navigation between source and header files.

Example relationship:

```text
main.c
main.h
```

Navigation should reuse native LSP capabilities and existing keymap infrastructure.

The proposed mapping is:

```text
<leader>ch
```

Before implementing it, inspect the existing keymap registry and confirm that the mapping is available.

A new navigation plugin is not justified solely for this feature.

## 11. Compilation Database Management

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

## 12. External Tool Inventory

| Tool | Category | Status |
|---|---|---|
| WinLibs GCC | Compiler | Approved and installed |
| clangd | Language server | Approved and installed |
| clang-format | Formatter | Approved and installed |
| clang-tidy | Static analysis | Approved and installed |
| CMake | Build integration | Supported where needed |
| Bear | Compilation database generation | Optional |

External tools must be managed through the existing modular Windows installation infrastructure.

The C installation script must install or validate only the dependencies it owns.

Shared dependencies must not be installed repeatedly by C and C++ packs.

For example:

- GCC and G++ belong to the shared WinLibs toolchain.
- clangd is shared between C and C++.
- clang-format is shared between C and C++.
- clang-tidy is shared between C and C++.

No Mason installation or automatic startup installation is permitted.

## 13. Configuration Ownership

| Responsibility | Owner |
|---|---|
| C filetypes | C language pack |
| C parser metadata | C language pack and central Treesitter configuration |
| C language-server association | Shared clangd configuration |
| LSP client lifecycle | Native Neovim LSP |
| LSP keymaps | Centralized LSP keymap infrastructure |
| Formatting | Conform |
| Formatting rules | `.clang-format` |
| Static-analysis rules | `.clang-tidy` |
| Compiler configuration | Project build system |
| Compilation database | Project build system |
| External dependencies | Modular installation scripts |

This separation prevents duplicate configuration and supports independent language-pack activation.

## 14. Validation Requirements and Current Status

Validation must distinguish between executable availability, configuration correctness, and actual editor behavior.

### 14.1 External tools

Verified versions:

| Tool | Verified version |
|---|---|
| GCC | 16.2.0 |
| G++ | 16.2.0 |
| clangd | 23.1.5 |
| clang-format | 23.1.5 |
| clang-tidy | 23.1.5 |

The WinLibs compiler is the MinGW-w64 POSIX UCRT x64 toolchain.

The installed LLVM clang executable targets MSVC. It must not be confused with the WinLibs GCC toolchain.

### 14.2 clangd and native LSP validation

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

### 14.3 Compilation database

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

### 14.4 Treesitter

- [ ] Confirm the C parser is installed.
- [ ] Confirm C buffers are recognized.
- [ ] Confirm syntax highlighting.
- [ ] Confirm no parser initialization errors.

### 14.5 Formatting

- [ ] Confirm Conform recognizes clang-format.
- [ ] Validate `:Format`.
- [ ] Validate `<leader>cf`.
- [ ] Confirm `.clang-format` is respected.
- [ ] Confirm format-on-save remains disabled.
- [ ] Confirm LSP formatting fallback remains disabled.

### 14.6 Static analysis

- [ ] Validate clang-tidy against the temporary C project.
- [ ] Validate compilation database usage.
- [ ] Validate project-specific `.clang-tidy` rules.

### 14.7 Header behavior

- [ ] Validate `.c` filetype detection.
- [ ] Validate C header handling.
- [ ] Validate C++ header handling after C++ implementation.
- [ ] Confirm headers are not incorrectly forced into C mode.

### 14.8 Build and execution

- [ ] Compile a basic C program with GCC.
- [ ] Link the resulting executable.
- [ ] Execute the validation program successfully.

### 14.9 Remaining integration work

- [ ] Validate source/header navigation.
- [ ] Validate automated smoke tests.
- [ ] Validate interactive workflows.
- [ ] Review installation-script integration.
- [ ] Complete documentation review.
- [ ] Commit and push after implementation and validation are complete.

## 15. Scope Exclusions

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

These exclusions keep Stage 13 focused on language support.

## 16. Relationship with C++ Support

C and C++ are independent language packs that share appropriate infrastructure.

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

## 17. Completion Criteria

C support can be marked complete when:

- [x] C language pack implemented.
- [x] clangd integrated through native Neovim LSP.
- [x] Shared clangd configuration supports independent C and C++ activation.
- [x] WinLibs GCC verified.
- [x] clangd verified.
- [x] clang-format verified as an installed executable.
- [x] clang-tidy verified as an installed executable.
- [x] Core C LSP requests validated, except Workspace Symbols.
- [x] Document Symbols validated.
- [ ] Workspace Symbols validated.
- [ ] C Treesitter parser validated.
- [ ] Conform formatting validated.
- [ ] clang-tidy analysis validated.
- [ ] Compilation database project behavior validated.
- [ ] C filetype and header behavior validated.
- [ ] Source/header navigation validated.
- [ ] Automated smoke tests pass.
- [ ] Interactive validation passes.
- [ ] Documentation finalized.
- [ ] Changes committed and pushed.

## 18. Final Architecture Decision

C support uses a native-first, project-aware development architecture.

Approved baseline:

- Language server: clangd.
- LSP client: Native Neovim.
- Parser: Treesitter C.
- Formatter: clang-format through Conform.
- Static analysis: clang-tidy.
- Compiler: GCC from WinLibs.
- Compilation metadata: `compile_commands.json`.
- Build integration: CMake where needed.
- Installation: Explicit Windows installation scripts.

C remains an independent language pack while reusing shared C/C++ infrastructure.

The project defines how its code is compiled. The language pack provides language-specific integration without embedding project build assumptions.

**Guiding principle:**

> Keep language configuration independent. Share infrastructure where it makes architectural sense. Let the project define how its code is compiled.
