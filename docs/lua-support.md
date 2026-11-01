# Lua Language Support

- **Status:** In progress — core LuaLS, StyLua, standalone-project, Tree-sitter, standalone Lua 5.4.9, LuaCheck repository linting, and LuaRocks setup validated; core failure-path checks remain open
- **Last validated:** 2026-11-01
- **Roadmap stage:** Stage 13 — Language Packs
- **Validated environment:** Windows, Neovim 0.12.6, PowerShell 7.6.7

## 1. Purpose and scope

Define the implementation, dependencies, workflows, installation tiers, and validation requirements for Lua language support in `nvim-config`.

Lua serves two purposes in this environment:

1. It is the implementation language for Neovim configuration and plugins.
2. It is a general-purpose language for standalone applications and libraries.

These environments have different runtime requirements. The language pack must support both without forcing every user to install a standalone Lua runtime, compiler, package manager, test framework, or additional linter.

The project follows this principle:

> **Minimum installation. Compose the rest.**

This document distinguishes implemented functionality, optional capabilities, completed tests, and outstanding validation. A test is considered passed only when its result has been observed and recorded.

## 2. Installation policy

Lua support has two installation tiers: **Core** and **Optional**.

The core tier provides the minimum tools needed for normal Lua and Neovim configuration development. Optional tools are installed only when a user has a corresponding development requirement.

### 2.1 Core installation

| Component | Tool | Responsibility | Classification |
|---|---|---|---|
| LSP client | Neovim built-in LSP | Client lifecycle, diagnostics, completion integration, and navigation | Core |
| Language server | LuaLS (`lua-language-server`) | Lua language intelligence | Core |
| Formatter | StyLua (`stylua`) | Lua formatting | Core |
| Formatter integration | Conform.nvim | Formatter execution through the shared formatting workflow | Existing shared infrastructure |
| Syntax parsing | Tree-sitter Lua parser | Parsing and syntax highlighting | Existing shared infrastructure |
| Server definition | `nvim-lspconfig` | Maintained `lua_ls` server definition | Existing shared infrastructure |
| Neovim API context | lazydev.nvim | Neovim API and plugin-library context for LuaLS | Existing shared infrastructure |

**Core external executables:**

- `lua-language-server`
- `stylua`

The built-in LSP client is part of Neovim. It is not a separate executable or plugin installation.

The existing plugins and shared modules remain part of the configuration architecture. They must not be duplicated inside the Lua language pack.

A user installing the default Lua support should not need standalone Lua 5.4, GCC, LuaCheck, LuaRocks, Busted, LuaUnit, or LuaCov.

### 2.2 Optional installation

| Component | Tool | Responsibility | When to install |
|---|---|---|---|
| Static analysis and linting | LuaCheck (`luacheck`) | Detect undefined globals, unused variables, and other code issues | When additional static analysis is wanted |
| Unit and integration testing | Busted | Lua test framework | When a project needs a dedicated test framework |
| Alternative test framework | LuaUnit | xUnit-style Lua testing | When a project prefers its API or reporting model |
| Lua coverage | LuaCov | Measure Lua source-code coverage | When test coverage reports are needed |
| Standalone runtime | Lua 5.4.x | Execute standalone Lua applications | When developing or running Lua 5.4 projects |
| Bytecode compiler | `luac` | Compile Lua source into bytecode | When bytecode compilation is needed |
| Native build toolchain | GCC or another supported C compiler | Build Lua and native Lua modules | When compiling Lua or C extensions |
| Package manager | LuaRocks (`luarocks`) | Install and manage Lua modules and native dependencies | When a project uses LuaRocks-managed dependencies |

Optional components must not be installed automatically by Neovim or by the default Lua language-pack setup.

**Current Windows environment:** LuaCheck `1.2.0` and LuaRocks `3.13.0` are installed as optional command-line tools. Their installation does not promote them to core dependencies. LuaCheck is used for an explicit repository lint command; it is not integrated as an LSP or automatic Neovim lint-on-save workflow.

**Important:** LuaRocks is not a prerequisite for LuaLS, StyLua, Tree-sitter, or ordinary Lua development. It is a package-management tool for projects that need it.

Busted and LuaUnit are alternatives for the same broad testing role. Do not install both by default.

LuaCov is for Lua source coverage. GCOV and LCOV belong to native-code coverage workflows and are not substitutes for LuaCov.

### 2.3 Separate native-development tools

The following tools are not part of the Lua language pack:

| Tool | Responsibility | When to use |
|---|---|---|
| GCOV | Coverage instrumentation for compiled native code | When measuring coverage of compiled C/C++ code |
| LCOV | Collect and present GCOV coverage data | When generating native-code coverage reports |
| AddressSanitizer (ASan) | Detect memory errors | When developing or debugging native code |
| ThreadSanitizer (TSan) | Detect data races | When debugging multithreaded native code |
| UndefinedBehaviorSanitizer (UBSan) | Detect selected forms of undefined behavior | When validating native C/C++ code |

These tools are relevant to native C/C++ development, including native Lua modules. They do not provide ordinary Lua source-code testing or coverage.

Keep them in a separate native-development toolchain.

### 2.4 Installation profiles

| Profile | Included |
|---|---|
| Default Lua support | LuaLS and StyLua, using existing Neovim infrastructure |
| Lua linting extension | LuaCheck (installed; invoked explicitly from the CLI) |
| Lua testing extension | Busted |
| Alternative Lua testing extension | LuaUnit instead of Busted |
| Lua coverage extension | LuaCov |
| Standalone Lua development | A project-selected Lua runtime |
| Lua 5.4 development | Lua 5.4 runtime and `luac` |
| Lua native-extension development | Lua development headers, libraries, and a C compiler |
| Lua package-management workflow | LuaRocks and the runtime it is configured to manage |
| Native-code QA | GCOV/LCOV and applicable compiler sanitizers |

The Lua 5.4 Windows build described in this document is an optional development setup. Its successful installation does not make it part of the default profile.

## 3. Architecture and responsibilities

Lua support uses the existing language-pack architecture, native Neovim LSP APIs, shared formatting infrastructure, and Tree-sitter integration.

| Capability | Component | Responsibility |
|---|---|---|
| LSP client | Neovim built-in LSP | LSP lifecycle and communication |
| Language intelligence | LuaLS (`lua_ls`) | Diagnostics, completion, hover, and code navigation |
| Server definition | `nvim-lspconfig` | Maintained LuaLS server definition |
| Neovim API context | lazydev.nvim | Neovim and plugin API context |
| Formatting | StyLua | Consistent Lua formatting |
| Formatter integration | Conform.nvim | Formatter resolution and execution |
| Optional linting | LuaCheck | Additional static analysis |
| Optional testing | Busted or LuaUnit | Lua unit and integration tests |
| Optional coverage | LuaCov | Lua source-code coverage |
| Syntax parsing and highlighting | Existing Tree-sitter integration | Lua parsing and highlighting |
| Language-pack registration | `lua/langs/init.lua` | Pack discovery, setup, and formatter metadata |
| Standalone runtime | Project-selected Lua | General-purpose Lua execution |
| Optional package management | LuaRocks | Lua module and dependency management |
| Native-code QA | GCC and native QA tools | Native module compilation and diagnostics |

The implementation must:

- Use Neovim's native `vim.lsp.config()` and `vim.lsp.enable()` APIs.
- Keep Lua-specific configuration in `lua/langs/lua.lua`.
- Reuse the existing language registry and formatter contract.
- Keep user-facing keymaps centralized in `lua/config/keymaps.lua`.
- Install external executables separately from Neovim plugins.
- Avoid Mason and other automatic tool installers.
- Keep formatting manual; format-on-save remains disabled.
- Avoid duplicate LSP, formatter, parser, and project-root infrastructure.
- Keep standalone Lua independent of Neovim's embedded LuaJIT.
- Keep optional tools out of the default installation.

Each component has one responsibility. LuaLS does not replace StyLua, StyLua does not replace LuaCheck, and Tree-sitter does not replace language diagnostics.

## 4. Runtime architecture

### 4.1 Neovim embedded LuaJIT

Neovim embeds LuaJIT to execute its configuration and plugins.

The `nvim-config` repository therefore targets Neovim's LuaJIT runtime and APIs.

The LuaLS configuration for this repository must recognize the Neovim environment and provide the appropriate API context.

The intended runtime setting is:

```lua
runtime = {
  version = "LuaJIT",
}
```

Neovim-specific globals and libraries must be available to LuaLS without making them global assumptions for unrelated Lua projects.

### 4.2 Standalone Lua projects

Standalone projects select their own Lua runtime.

A project targeting Lua 5.4 can use:

```lua
runtime = {
  version = "Lua 5.4",
}
```

The runtime setting belongs to the project, not to a global configuration that forces every Lua workspace to use Lua 5.4.

A project-specific `.luarc.json` or `.luarc.jsonc` takes precedence over the fallback configuration supplied by the language pack.

### 4.3 Runtime separation policy

| Environment | Runtime | Intended use |
|---|---|---|
| Neovim configuration | Embedded LuaJIT | Neovim configuration and plugin development |
| Standalone Lua project | Project-selected runtime | General Lua development |
| Lua 5.4 project | Lua 5.4.x | Lua 5.4 execution and development |
| Lua native-extension project | Matching Lua runtime and development files | C API and native module development |

Do not configure LuaLS globally for Lua 5.4 simply because standalone Lua 5.4 is installed.

The standalone Lua 5.4 runtime does not replace, upgrade, or modify Neovim's embedded LuaJIT.

## 5. Language server: LuaLS

LuaLS provides diagnostics, completion, hover, definition navigation, and other language-server capabilities.

The `nvim-lspconfig` plugin supplies the maintained `lua_ls` server definition. It does not install the LuaLS executable.

The Lua language pack uses Neovim's native LSP APIs:

- `vim.lsp.config("lua_ls", ...)`
- `vim.lsp.enable("lua_ls")`

The language pack checks whether `lua-language-server` is available before configuring and enabling the server. If the executable is missing, it skips LuaLS setup without preventing unrelated configuration modules from loading.

### 5.1 Runtime and workspace configuration

The fallback configuration for `nvim-config` uses LuaJIT.

The current implementation also:

- Preserves project-specific `.luarc.json` and `.luarc.jsonc` files.
- Applies fallback workspace settings only when a project configuration file is not found at the workspace root.
- Disables LuaLS third-party workspace checks in the fallback configuration.
- Includes the Neovim runtime and `luv` library in the fallback workspace library.
- Disables LuaLS telemetry.
- Uses the existing completion and diagnostic settings.
- Leaves formatting to StyLua and Conform.

The effective fallback settings must remain consistent with the Neovim runtime.

**Configuration accuracy:** The current module's initial `settings` block does not explicitly declare `Lua.diagnostics.globals = { "vim" }`. Do not document that as a direct setting unless it is added to the implementation. Neovim API awareness is also provided through lazydev and the configured workspace libraries.

### 5.2 Project configuration and isolation

LuaLS must use the correct workspace and runtime for each project.

- The `nvim-config` repository targets LuaJIT.
- Standalone Lua projects must not automatically inherit Neovim-specific assumptions.
- Project-specific `.luarc.json` and `.luarc.jsonc` settings must be respected.
- Project-specific runtime settings must not be overwritten by the fallback configuration.

The current `has_luarc()` check looks for configuration files at the workspace root. This is a deliberate boundary of the current implementation. If nested workspace configurations become a requirement, evaluate that behavior separately rather than silently adding a second configuration mechanism.

The standalone-project and project-specific diagnostic tests have passed. The Lua 5.4 runtime override has not been independently verified.

### 5.3 lazydev.nvim

lazydev.nvim improves LuaLS awareness of Neovim APIs and installed Lua libraries during Neovim configuration and plugin development.

It does not:

- Install LuaLS.
- Replace the native LSP client.
- Replace project-specific runtime settings.
- Configure standalone Lua projects to use Neovim APIs.

Keep lazydev within the existing plugin architecture.

## 6. Formatting: StyLua and Conform

StyLua is the default Lua formatter and is integrated through the shared Conform workflow.

The Lua language pack declares formatter metadata:

```lua
local M = {
  formatters = {
    lua = { "stylua" },
  },
}
```

This is the formatter metadata contract, not a replacement for the complete language-pack module.

The workflow is:

1. `lua/langs/lua.lua` declares StyLua as the Lua formatter.
2. `lua/langs/init.lua` collects formatter metadata.
3. `lua/config/format.lua` resolves the configured formatter.
4. Conform invokes StyLua through the existing `:Format` command.

### 6.1 Formatting policy

- Use the repository's existing StyLua configuration.
- Use `:Format` for manual formatting.
- Keep `lsp_format = "never"` in the shared Conform options.
- Do not enable format-on-save.
- Report unavailable formatters without installing them automatically.
- Keep formatter selection centralized in the existing language and formatting modules.
- Do not add a second formatter dispatcher.

StyLua version `2.6.0` was observed in the development environment. The repository-wide formatting check and manual `:Format` workflow passed.

## 7. Optional linting: LuaCheck

LuaCheck is an optional static analyzer and linter. It can identify issues such as undefined globals, unused variables, and other code-quality problems.

It complements LuaLS rather than replacing it.

| Tool | Responsibility |
|---|---|
| LuaLS | Interactive language intelligence and diagnostics |
| LuaCheck | Additional static analysis and linting |
| StyLua | Formatting |
| Tree-sitter | Parsing and highlighting |

LuaCheck is not required for the default Lua installation.

### 7.1 Runtime-specific linting

LuaCheck must use the standard that matches the project being checked.

For Neovim configuration projects:

```lua
std = "luajit"

globals = {
  "vim",
}

max_line_length = 120
max_code_line_length = 120
```

For standalone Lua 5.4 projects, use the Lua 5.4 standard only when the installed LuaCheck release exposes and accepts that standard:

```lua
std = "lua54"

max_line_length = 120
max_code_line_length = 120
```

Do not use one global configuration that treats all Lua files as LuaJIT or Lua 5.4.

Prefer project-local `.luacheckrc` files or an equivalent explicit project configuration. This prevents Neovim globals from being accepted accidentally in standalone projects and prevents standalone Lua assumptions from leaking into Neovim configuration checks.

**Compatibility qualification:** LuaCheck's current upstream project identifies syntax support for Lua 5.1 through 5.4 and LuaJIT. However, syntax support and standard-library global definitions are separate capabilities. Verify the installed release's supported `std` names before using `std = "lua54"`. Do not assume that the standard name is valid merely because Lua 5.4 syntax is supported.

LuaCheck's Lua 5.4 attribute support also needs to be considered carefully. Parser acceptance of `<const>` and `<close>` does not necessarily mean that the linter performs semantic checks specific to those attributes.

### 7.2 LuaCheck integration policy

The current repository CLI workflow is adopted and validated. Any broader integration must follow these rules:

- Keep it optional.
- Install it as an external executable.
- Do not add a second LSP server for it.
- Do not duplicate LuaLS diagnostics.
- Keep its project-specific configuration outside the shared LuaLS setup.
- Decide separately whether to run it manually, through a script, or through the existing lint workflow.
- Do not add automatic installation or automatic execution until the linting workflow is explicitly configured and tested.

**Current implementation and validation status:**

- LuaCheck `1.2.0` is installed in the user LuaRocks tree.
- The `luacheck` command is available through the user's PATH.
- The complete repository was checked using the LuaJIT standard and explicit `vim` and `Snacks` globals.
- All 33 Lua files passed with zero warnings and zero errors.
- A temporary diagnostic fixture confirmed that LuaCheck reports an unused local and an undefined global. The fixture was removed after the test.
- No `.luacheckrc` has been added to the repository.
- LuaCheck is not configured as an LSP, a Neovim diagnostic provider, a save hook, or an automatic startup task.
- Lua 5.4-specific standard selection and `<const>` / `<close>` behavior have not been independently tested.

The repository CLI lint workflow is validated. A general-purpose LuaCheck integration for arbitrary standalone Lua 5.4 projects remains unverified.

## 8. Optional testing and QA tools

Testing and QA tools are separate from the default language pack. They must be selected according to the type of Lua project and the validation it needs.

### 8.1 Lua test frameworks

Two test frameworks are under consideration:

| Tool | Role | Recommendation |
|---|---|---|
| Busted | Unit, integration, and functional testing | Preferred optional framework |
| LuaUnit | Unit testing with an xUnit-style API | Alternative to Busted |

Busted is the preferred choice if a dedicated Lua test framework is needed. It provides a specification-style testing workflow and supports structured test output.

LuaUnit is a valid alternative for projects that prefer an xUnit-style API.

Do not install both by default. They solve the same broad testing requirement, and using both would add dependencies without an established need.

**Project policy:** The existing `nvim-config` headless smoke-test suite remains the primary validation mechanism for the Neovim configuration. Do not introduce Busted or LuaUnit merely to replace working smoke tests. Consider a dedicated test framework when a Lua module or standalone application develops a meaningful independent test suite.

### 8.2 Lua source-code coverage

LuaCov is the recommended optional coverage tool.

It measures Lua source-code execution during tests and can produce coverage reports.

Use LuaCov when:

- A project has a dedicated Lua test suite.
- Test coverage is a meaningful quality metric.
- The team needs to identify untested source paths.
- Coverage reports are useful in local development or CI.

LuaCov is not a test runner. It measures coverage from test execution and complements a test framework such as Busted.

Do not add LuaCov to the default Lua installation. Coverage instrumentation is useful only when a project has a test workflow that can produce meaningful coverage data.

### 8.3 Native-code coverage

GCOV and LCOV belong to native-code coverage workflows.

| Tool | Role |
|---|---|
| GCOV | Collect coverage information from instrumented compiled code |
| LCOV | Collect and present GCOV coverage data in report form |

These tools are appropriate when developing native C/C++ components, such as Lua C modules.

They do not replace LuaCov and should not be installed for ordinary Lua source-code coverage.

### 8.4 Native-code sanitizers

Sanitizers are compiler-assisted diagnostics for native code.

| Sanitizer | Purpose |
|---|---|
| ASan | Detect memory errors, including out-of-bounds access and use-after-free |
| TSan | Detect data races |
| UBSan | Detect selected forms of undefined behavior |

These tools are useful when developing or debugging native C/C++ components.

They do not provide ordinary Lua script diagnostics or replace LuaLS, LuaCheck, or LuaCov.

Keep sanitizer support in the native-development toolchain. Do not make it a dependency of the Lua language pack.

### 8.5 Testing and QA selection policy

| Development requirement | Recommended tool |
|---|---|
| Neovim configuration validation | Existing headless smoke tests |
| Lua unit and integration tests | Busted |
| Alternative xUnit-style tests | LuaUnit |
| Static analysis | LuaCheck |
| Lua source coverage | LuaCov |
| Native C/C++ coverage | GCOV and LCOV |
| Native memory diagnostics | ASan |
| Native race diagnostics | TSan |
| Native undefined-behavior diagnostics | UBSan |

All tools in this section are optional except the existing repository validation workflow.

No test framework, coverage tool, native coverage utility, or sanitizer should be installed automatically by the default Lua language-pack setup.

## 9. Optional LuaRocks package management

LuaRocks manages Lua modules and project dependencies through packages called rocks.

It is useful when a standalone Lua project depends on modules distributed through LuaRocks or needs to build and manage native Lua modules.

LuaRocks is not required for:

- Neovim's built-in LSP client.
- LuaLS.
- StyLua.
- Tree-sitter.
- Ordinary standalone Lua execution.
- The existing Lua language-pack setup.

### 9.1 Runtime alignment

LuaRocks must be configured for the Lua runtime used by the project.

For a Lua 5.4 project, it must use the matching Lua 5.4 interpreter and, when building native modules, the corresponding headers and libraries.

Do not let LuaRocks silently use a different Lua installation found earlier on `PATH`.

### 9.2 Native module requirements

Building native Lua modules may require:

- A compatible C compiler.
- Lua development headers.
- Lua libraries or import libraries.
- Correct runtime and architecture selection.

The standalone Lua 5.4.9 Windows installation described below provides the runtime and development files for that optional workflow.

LuaRocks installation and configuration remain separate from the default language-pack installation.

### 9.3 Current Windows installation

LuaRocks `3.13.0` is installed and configured for the standalone Lua `5.4.9` toolchain.

| Setting | Current value |
|---|---|
| LuaRocks version | `3.13.0` |
| Lua runtime | Lua `5.4.9` |
| LuaRocks installation root | `%LOCALAPPDATA%\Programs\LuaRocks` |
| Main command | `%LOCALAPPDATA%\Programs\LuaRocks\luarocks.bat` |
| Configuration file | `%LOCALAPPDATA%\Programs\LuaRocks\config-5.4.lua` |
| System rock tree | `%LOCALAPPDATA%\LuaRocks\5.4` |
| User rock tree | `%APPDATA%\LuaRocks` |
| Compiler | WinLibs GCC, target `x86_64-w64-mingw32` |
| Make executable | `mingw32-make.exe` from the WinLibs toolchain |

The LuaRocks configuration sets `variables.MAKE` to the available `mingw32-make.exe`. The standalone Lua `5.4` binary directory and the LuaRocks command and rock `bin` directories are included in the Windows user PATH.

The following command completed successfully:

```powershell
luarocks --version
```

Observed output:

```text
C:\Users\Administrator\AppData\Local\Programs\LuaRocks\luarocks.lua 3.13.0 LuaRocks main command-line interface
```

The command-line version output identifies the LuaRocks entry point and version. It does not use the shorter `LuaRocks 3.13.0` format.

### 9.4 LuaCheck installed through LuaRocks

LuaCheck was installed into the user rock tree:

```powershell
luarocks --local install luacheck
```

The installation completed successfully and installed:

- LuaCheck `1.2.0`
- `argparse` `0.7.2`
- `luafilesystem` `1.9.0`

The resolved executable is:

```text
%APPDATA%\LuaRocks\bin\luacheck.bat
```

The following command completed successfully:

```powershell
luacheck --version
```

The reported runtime is PUC-Rio Lua `5.4`. LuaLanes is reported as not found; LuaLanes is optional and its absence did not prevent LuaCheck from running.

This validates installation of LuaCheck as a LuaRocks user package. It does not establish that every native rock can be compiled or that all standalone Lua 5.4 lint standards have been configured.

## 10. Optional standalone Lua 5.4.9 — Windows

### 10.1 Decision

Build standalone Lua from the official Lua source distribution using WinLibs GCC.

This is an optional development environment. It is not a prerequisite for the default Lua language pack.

| Property | Configuration |
|---|---|
| Lua version | `5.4.9` |
| Source archive | `lua-5.4.9.tar.gz` |
| Source URL | `https://www.lua.org/ftp/lua-5.4.9.tar.gz` |
| SHA-256 | `2335b6c582a52654f94612bf10d2f4672805d05329aa6568b1d8cd9e5c6fb8e6` |
| Compiler | WinLibs GCC 16.2.0 |
| Target | `x86_64-w64-mingw32` |
| Architecture | Windows x64 |
| Thread model | POSIX |
| C runtime | UCRT |
| Installation root | `C:\DevTools\Lua\5.4` |

The GCC distribution was installed through WinGet using the Brecht Sanders WinLibs package.

Observed compiler version:

```text
gcc.exe (MinGW-W64 x86_64-ucrt-posix-seh, built by Brecht Sanders, r3) 16.2.0
```

### 10.2 Build workspace

The build workspace is separate from the final installation:

```text
C:\DevTools\Lua\
├── downloads\
│   └── lua-5.4.9.tar.gz
├── source\
│   └── lua-5.4.9\
├── build\
│   └── lua-5.4.9\
│       ├── lua54.dll
│       ├── liblua54.dll.a
│       ├── lua.exe
│       └── luac.exe
└── 5.4\
    ├── bin\
    ├── include\
    └── lib\
```

Directory responsibilities:

- `downloads/` holds the verified source archive.
- `source/` holds the extracted Lua source.
- `build/` holds generated artifacts and validation executables.
- `5.4/` holds the final installed runtime and development files.

### 10.3 Installation layout

The completed installation contains:

```text
C:\DevTools\Lua\5.4\
├── bin\
│   ├── lua.exe
│   ├── luac.exe
│   └── lua54.dll
├── include\
│   ├── lua.h
│   ├── luaconf.h
│   ├── lauxlib.h
│   ├── lualib.h
│   └── lua.hpp
└── lib\
    └── liblua54.dll.a
```

| Component | Responsibility |
|---|---|
| `lua.exe` | Standalone Lua interpreter dynamically linked to `lua54.dll` |
| `luac.exe` | Standalone Lua bytecode compiler |
| `lua54.dll` | Shared Lua runtime |
| `liblua54.dll.a` | GCC import library for external C applications |
| `include/` | Public Lua development headers |

The interpreter and shared runtime are installed together in `bin`, allowing Windows to locate the DLL beside the executable.

The standalone compiler is built independently and does not depend on `lua54.dll`.

The shared DLL and import library provide the components needed for external C applications to link against the Lua runtime.

### 10.4 Installation scripts

Standalone Lua installation and PATH configuration are deliberately separate operations.

| Script | Responsibility |
|---|---|
| `scripts/install/windows/lua-install.ps1` | Download, checksum verification, source preparation, GCC validation, compilation, build validation, and installation |
| `scripts/install/windows/lua-path.ps1` | Persistent user PATH configuration, current-process PATH update, and executable/runtime validation |
| `scripts/install/windows/luarocks-install.ps1` | LuaRocks installation or existing-installation validation, compiler configuration, PATH setup, and final verification |

#### `lua-install.ps1`

The installation script:

1. Prepares the Lua workspace directories.
2. Downloads the official source archive when necessary.
3. Verifies the pinned SHA-256 checksum.
4. Prepares and validates the source tree.
5. Validates the WinLibs GCC toolchain.
6. Builds the shared Lua runtime and GCC import library.
7. Builds the Lua interpreter.
8. Builds standalone `luac.exe`.
9. Validates the build artifacts and DLL exports.
10. Tests interpreter execution and bytecode compilation.
11. Tests external C API linkage.
12. Stages, validates, and commits the final installation.

The script must not silently overwrite an existing installation.

#### `lua-path.ps1`

The PATH configuration script operates on an existing installation. It does not download, compile, install, overwrite, or remove Lua files.

Its responsibilities are:

1. Confirm that the expected installation files exist.
2. Add the Lua `bin` directory to the persistent Windows user PATH if it is not already present.
3. Update `$env:Path` in the current PowerShell process.
4. Resolve `lua` and `luac` through `Get-Command`.
5. Verify both executable versions.
6. Check `_VERSION` and `package.cpath`.

The script must be safe to run repeatedly and must not create duplicate PATH entries.

No machine-wide PATH modification is required.

#### `luarocks-install.ps1`

The optional LuaRocks installer is located at:

```text
scripts/install/windows/luarocks-install.ps1
```

It validates the standalone Lua installation and MinGW toolchain, checks or installs LuaRocks, configures the Make executable, updates the user PATH when needed, and verifies the resulting LuaRocks and Lua versions.

**Observed validation:**

- Existing-installation path: PASS. The script detected LuaRocks `3.13.0`, configured `variables.MAKE`, checked PATH entries, and completed final verification.
- Fresh-installation path: NOT TESTED.
- `-Force` path: NOT TESTED.

Do not describe the installer as fully branch-tested until the fresh-installation and force-reinstallation paths have been exercised in a disposable environment.

No machine-wide PATH modification is required.

### 10.5 PATH configuration

The standalone Lua executable directory is:

```text
C:\DevTools\Lua\5.4\bin
```

The persistent user PATH contains this directory.

The distinction between persistent and process PATH is important:

- The persistent user PATH is saved to the Windows user environment.
- The current-process PATH is updated by the script so commands are immediately available in the running PowerShell session.
- Newly opened PowerShell sessions inherit the persistent user PATH.

No PATH configuration is required for Neovim's embedded LuaJIT runtime.

### 10.6 Verified installation results

**Validation date:** 2026-10-30

| Validation | Result |
|---|---|
| Official source archive SHA-256 | PASS |
| Existing source tree structural validation | PASS |
| GCC target validation | PASS |
| POSIX thread model validation | PASS |
| GNU linker and objdump discovery | PASS |
| GCC compilation and execution | PASS |
| UCRT PE import verification | PASS |
| Shared `lua54.dll` build | PASS |
| GCC import library build | PASS |
| `lua.exe` build | PASS |
| Standalone `luac.exe` build | PASS |
| Lua interpreter execution | PASS |
| Lua bytecode compilation | PASS |
| DLL dependency validation | PASS |
| Lua API export validation | PASS |
| External C API linkage and execution | PASS |
| Staged installation validation | PASS |
| Final installation validation | PASS |
| Persistent user PATH configuration | PASS |
| Current-process PATH update | PASS |
| Fresh PowerShell command resolution | PASS |

Fresh PowerShell session output:

```text
PS C:\Users\Administrator> lua -v
Lua 5.4.9  Copyright (C) 1994-2026 Lua.org, PUC-Rio

PS C:\Users\Administrator> luac -v
Lua 5.4.9  Copyright (C) 1994-2026 Lua.org, PUC-Rio
```

PowerShell resolves:

```text
C:\DevTools\Lua\5.4\bin\lua.exe
C:\DevTools\Lua\5.4\bin\luac.exe
```

The runtime reports:

```text
Lua 5.4
```

Its C module search path includes:

```text
C:\DevTools\Lua\5.4\bin\?.dll
C:\DevTools\Lua\5.4\bin\..\lib\lua\5.4\?.dll
C:\DevTools\Lua\5.4\bin\loadall.dll
.\?.dll
```

This confirms that the standalone runtime and its default C module search path are operational.

**Standalone Lua 5.4.9 Windows installation: COMPLETE.**

This completion applies only to the optional standalone runtime installation. It does not make Lua 5.4 a requirement for the default Lua language pack or close the remaining Lua language-pack validation requirements.

## 11. Module responsibilities and dependencies

### 11.1 Relevant modules

| Path | Responsibility |
|---|---|
| `lua/langs/lua.lua` | LuaLS configuration and Lua formatter metadata |
| `lua/langs/init.lua` | Language-pack discovery, setup, and metadata collection |
| `lua/config/lsp.lua` | Shared LSP behavior and lifecycle |
| `lua/config/languages.lua` | Language and formatter preferences |
| `lua/config/format.lua` | Conform integration and formatter resolution |
| `lua/plugins/lsp.lua` | LSP-related plugin declarations |
| `lua/plugins/lazydev.lua` | lazydev setup |
| `lua/plugins/conform.lua` | Conform plugin declaration |
| `lua/plugins/treesitter.lua` | Existing Tree-sitter integration |
| `lua/config/keymaps.lua` | Centralized user-facing keymaps |

Preserve existing module interfaces. Do not create duplicate modules or rebuild working shared infrastructure merely to match the documentation.

### 11.2 Dependencies by installation tier

| Dependency | Tier | Type | Installation policy |
|---|---|---|---|
| `lua-language-server` | Core | External executable | Installed separately and available on `PATH` |
| `stylua` | Core | External executable | Installed separately and available on `PATH` |
| `nvim-lspconfig` | Existing infrastructure | Neovim plugin | Managed by the existing `vim.pack` workflow |
| `lazydev.nvim` | Existing infrastructure | Neovim plugin | Managed by the existing `vim.pack` workflow |
| Conform.nvim | Existing infrastructure | Neovim plugin | Managed by the existing `vim.pack` workflow |
| Tree-sitter integration and Lua parser | Existing infrastructure | Plugin and parser | Managed by the existing integration |
| `luacheck` | Optional | External executable | Installed only when linting is wanted |
| `busted` | Optional | Test framework | Installed only when a dedicated test framework is needed |
| LuaUnit | Optional alternative | Test framework | Used instead of Busted when preferred |
| LuaCov | Optional | Coverage tool | Installed only when Lua coverage is needed |
| Lua 5.4.x | Optional | External runtime | Installed only for standalone Lua 5.4 development |
| GCC | Optional | Compiler | Required for the selected native build workflow |
| LuaRocks | Optional | External package manager | Installed only when project dependencies require it |
| GCOV/LCOV | Separate native toolchain | Native coverage tools | Used for compiled native-code coverage |
| ASan/TSan/UBSan | Separate native toolchain | Compiler instrumentation | Used for native-code diagnostics |

Recorded development-environment versions:

- Neovim `0.12.6`
- LuaLS `3.19.2`
- StyLua `2.6.0`
- Standalone Lua `5.4.9`
- WinLibs GCC `16.2.0`
- LuaCheck `1.2.0` (optional CLI linter)
- LuaRocks `3.13.0` (optional package manager)

These are observed versions, not minimum supported versions.

Installation and executable verification instructions belong in `docs/dependencies.md`. Neovim startup must not install, update, or provision external tools.

## 12. Validation procedures and results

Validation distinguishes automated checks from interactive behavior. Passing automated checks does not, by itself, prove that every workspace scenario or failure path works.

### 12.1 Automated repository checks

Run from the `nvim-config` repository root in PowerShell:

```powershell
Set-Location "$HOME\Desktop\nvim-config"

stylua --check .

nvim --headless -u NONE -l scripts/check-syntax.lua

nvim --headless -u init.lua -c "luafile scripts/smoke.lua"

$FilePaths = Get-ChildItem -Path . -Recurse -Filter "*.lua" -File |
    Where-Object {
        $_.FullName -notmatch '[\\/](\.git|node_modules|vendor|build|dist)[\\/]'
    } |
    ForEach-Object { $_.FullName }

foreach ($File in $FilePaths) {
    & luac -p $File

    if ($LASTEXITCODE -ne 0) {
        throw "Lua syntax validation failed: $File"
    }
}

& luacheck --no-config --std luajit --globals vim Snacks --no-color $FilePaths

git diff --check
```

| Command | Expected result | Recorded result |
|---|---|---|
| `stylua --check .` | No formatting violations | PASS |
| `nvim --headless -u NONE -l scripts/check-syntax.lua` | All Lua files pass syntax validation | PASS — 31 files |
| `nvim --headless -u init.lua -c "luafile scripts/smoke.lua"` | Configuration smoke checks pass | PASS |
| Repository LuaCheck command shown above | All discovered Lua files pass the LuaJIT lint profile | PASS — 33 files, 0 warnings, 0 errors; exit code 0 |
| PowerShell `luac -p` loop | Every discovered Lua file parses successfully | PASS — 33 files |
| `git diff --check` | No whitespace errors | PASS at the last recorded Git review; rerun after applying this document update |

The smoke test passed on Neovim `0.12.6`. Reported coverage includes plugin registration, language-pack and LSP configuration, completion and snippets, formatting and linting configuration, Git/project/session registration, native grep and quickfix, native commenting, and the module-failure contract.

Record command exit statuses when repeating the tests. Do not infer that an external executable works merely because a configuration smoke test passes.

### 12.2 Executable and version checks

Run:

```powershell
Get-Command nvim -ErrorAction SilentlyContinue
Get-Command lua-language-server -ErrorAction SilentlyContinue
Get-Command stylua -ErrorAction SilentlyContinue
Get-Command luacheck -ErrorAction SilentlyContinue
Get-Command busted -ErrorAction SilentlyContinue
Get-Command luarocks -ErrorAction SilentlyContinue
Get-Command lua -ErrorAction SilentlyContinue
Get-Command luac -ErrorAction SilentlyContinue
Get-Command git -ErrorAction SilentlyContinue
```

Inspect versions for installed tools:

```powershell
nvim --version
lua-language-server --version
stylua --version
luacheck --version
busted --version
luarocks --version
lua -v
luac -v
git --version
```

These commands establish executable discovery and report versions. They do not prove correct LSP attachment, successful formatting, correct project-specific linting, or successful test execution.

Optional executables should be checked only when the corresponding optional tool is installed.

### 12.3 LuaLS attachment and configuration

Open a Lua file in Neovim.

Check the filetype:

```vim
:set filetype?
```

Expected: `filetype=lua`.

Inspect attached LSP clients:

```vim
:lua vim.print(vim.lsp.get_clients({ bufnr = 0 }))
```

Inspect the LuaLS workspace root:

```vim
:lua for _, c in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do if c.name == "lua_ls" then vim.print(c.root_dir) end end
```

Inspect the configured server:

```vim
:lua vim.print(vim.lsp.config.lua_ls)
```

Expected results:

- LuaLS attaches to the Lua buffer.
- The workspace root matches the intended project.
- The effective configuration contains the expected runtime and workspace settings.

**Recorded result: PASS.** LuaLS attachment, filetype, repository root, effective settings, diagnostics, hover, completion, definition navigation, and recognition of the `vim` global were tested interactively.

`:LspInfo` is not a built-in command in this configuration. Use the native LSP APIs above instead of adding a plugin solely for that command.

### 12.4 Diagnostics

To test undefined-global diagnostics, temporarily add an intentional error:

```lua
print(deliberately_undefined_global)
```

Inspect the current buffer's diagnostics:

```vim
:lua vim.print(vim.diagnostic.get(0))
```

Expected: LuaLS reports the undefined global.

Remove the deliberate error after testing.

**Recorded result: PASS.**

### 12.5 Completion, hover, and navigation

Use a Neovim API expression such as:

```lua
vim.api.nvim_get_current_buf()
```

Test completion and hover using the configured editor workflow. Test definition navigation and references on a locally defined symbol.

Expected: completion and hover provide relevant information, definition navigation reaches the correct declaration, and references identify relevant occurrences.

**Recorded result: PASS** for completion, hover, definition navigation, and references.

### 12.6 StyLua and Conform

Inspect formatter configuration:

```vim
:ConformInfo
```

Expected: StyLua is available for Lua buffers and the existing Conform configuration is active.

Format a Lua buffer:

```vim
:Format
```

Expected: StyLua formats the buffer using the repository's formatting configuration.

**Recorded result: PASS.** Conform reported StyLua as ready, and actual formatting through `:Format` succeeded. The repository-wide StyLua check also passed.

### 12.7 Standalone Lua project

Create a disposable project:

```powershell
$Project = "$HOME\Desktop\lua-standalone-validation"

New-Item -ItemType Directory -Force $Project | Out-Null
Set-Location $Project

git init
```

Create `main.lua`:

```lua
local function greet(name)
  return "Hello, " .. name
end

print(greet("Lua"))

-- Neovim's vim API is not part of an ordinary standalone Lua runtime.
print(vim.api.nvim_get_current_buf())
```

Open the file:

```powershell
nvim main.lua
```

Verify:

```vim
:set filetype?
:lua vim.print(vim.lsp.get_clients({ bufnr = 0 }))
:lua for _, c in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do if c.name == "lua_ls" then vim.print(c.root_dir) end end
:lua vim.print(vim.diagnostic.get(0))
```

Expected:

- The filetype is Lua.
- LuaLS attaches.
- The root corresponds to the standalone project.
- Diagnostics reflect the standalone project's settings rather than silently assuming all Neovim APIs exist.

**Recorded result: PASS**, based on the completed interactive validation.

### 12.8 Project-specific `.luarc.json`

Create a disposable project:

```powershell
$Project = "$HOME\Desktop\lua-luarc-validation"

New-Item -ItemType Directory -Force $Project | Out-Null
Set-Location $Project

git init
```

Create `.luarc.json`:

```json
{
  "runtime.version": "Lua 5.4",
  "diagnostics.globals": ["project_marker"],
  "workspace.checkThirdParty": false,
  "telemetry.enable": false
}
```

Create `main.lua`:

```lua
print(project_marker)
print(unconfigured_marker)
```

Open the project:

```powershell
nvim main.lua
```

Inspect the workspace and diagnostics:

```vim
:set filetype?
:lua vim.print(vim.lsp.get_clients({ bufnr = 0 }))
:lua for _, c in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do if c.name == "lua_ls" then vim.print(c.root_dir) end end
:lua vim.print(vim.diagnostic.get(0))
```

Expected:

- LuaLS attaches to the project.
- The root corresponds to the directory containing `.luarc.json`.
- `project_marker` is recognized as a configured global.
- `unconfigured_marker` produces an undefined-global diagnostic.

**Recorded result: PASS.** The project root was reported as `lua-luarc-validation`; `project_marker` was accepted and `unconfigured_marker` was diagnosed.

**Limitation:** The project-specific diagnostic override was verified. The `Lua 5.4` runtime override was not independently confirmed and must not be recorded as passed.

### 12.9 Tree-sitter

In a Lua buffer, run:

```vim
:set filetype?
:lua vim.print(vim.treesitter.language.get_lang("lua"))
:lua vim.print(vim.treesitter.get_parser(0):lang())
:lua vim.print(vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()] ~= nil)
```

Expected:

- Filetype is `lua`.
- Language mapping is `lua`.
- Parser language is `lua`.
- The active highlighter check returns `true` when highlighting is active.

Also visually inspect the buffer for syntax highlighting.

**Recorded result: PASS**, as confirmed by the completed filetype, mapping, parser, active-highlighter, and visual-highlighting checks.

### 12.10 Standalone Lua 5.4.9 runtime

Run the following from a fresh PowerShell session:

```powershell
lua -v
luac -v

Get-Command lua
Get-Command luac

lua -e "print(_VERSION); print(package.cpath)"
```

Expected:

- `lua -v` reports Lua 5.4.9.
- `luac -v` reports Lua 5.4.9.
- PowerShell resolves both commands from `C:\DevTools\Lua\5.4\bin\`.
- `_VERSION` reports `Lua 5.4`.
- `package.cpath` contains the installed runtime's native DLL search locations.

**Recorded result: PASS.** Both executables were successfully resolved and executed from a fresh PowerShell session. The persistent user PATH and Lua C module search path were validated.

### 12.11 Optional LuaCheck validation

LuaCheck is not part of the default installation. It is installed in the current Windows environment as an optional, explicitly invoked CLI tool.

#### Repository lint command

From the repository root, discover the Lua files and run the project lint profile:

```powershell
$FilePaths = Get-ChildItem -Path . -Recurse -Filter "*.lua" -File |
    Where-Object {
        $_.FullName -notmatch '[\\/](\.git|node_modules|vendor|build|dist)[\\/]'
    } |
    ForEach-Object { $_.FullName }

& luacheck `
    --no-config `
    --std luajit `
    --globals vim Snacks `
    --no-color `
    $FilePaths

$LintExitCode = $LASTEXITCODE

"LuaCheck exit code: $LintExitCode"
"Lua files checked: $($FilePaths.Count)"

if ($LintExitCode -ne 0) {
    throw "Repository LuaCheck validation failed."
}
```

The command deliberately uses:

- `--no-config` so no untracked or machine-wide `.luacheckrc` silently changes the result.
- `--std luajit` because the repository targets Neovim's LuaJIT runtime.
- `--globals vim Snacks` because these are intentional globals used by the Neovim configuration.
- No `--only 631` or warning suppression, so the complete enabled LuaCheck rule set is evaluated.
- A file list that excludes `.git`, dependency, vendor, build, and distribution directories.

**Recorded result — 2026-11-01: PASS.**

```text
Total: 0 warnings / 0 errors in 33 files
LuaCheck exit code: 0
Lua files checked: 33
```

Lua syntax was also checked independently with `luac -p` across the same 33 discovered Lua files. All files parsed successfully.

#### Diagnostic behavior

A temporary test file containing an unused local variable (`unused_value`) and an undefined global (`undefined_variable`) was used to verify diagnostic behavior. LuaCheck reported both warnings and returned a nonzero exit code, as expected. The temporary file was removed after the test.

#### Scope and limitations

- LuaCheck `1.2.0` is installed through LuaRocks in the user rock tree.
- No repository `.luacheckrc` has been created.
- The repository lint command is a manual CLI workflow.
- LuaCheck is not an LSP server and has not been added as a Neovim diagnostic provider, save hook, or automatic startup task.
- The `lua54` standard name has not been tested with the installed release.
- Lua 5.4 `<const>` and `<close>` behavior has not been independently tested.

For a standalone Lua 5.4 project, first verify the installed LuaCheck release's supported standard names and syntax handling. Do not assume that `std = "lua54"` is accepted merely because the parser supports Lua 5.4 syntax.

### 12.12 Optional testing framework validation

Busted and LuaUnit are optional. Do not install both merely to complete the Lua language pack.

If Busted is adopted, verify:

- The executable is available in the intended project environment.
- A minimal test suite runs successfully.
- Passing and failing tests produce the expected exit status.
- Assertions and test discovery work as expected.
- The test runner works with the project's selected Lua runtime.
- CI output is usable if the project requires automated reporting.

If LuaUnit is selected instead, perform equivalent checks for its test discovery, assertions, exit status, runtime compatibility, and reporting.

A successful version check alone does not prove that a test framework is correctly configured.

### 12.13 Optional LuaCov validation

When LuaCov is adopted, verify:

- Coverage instrumentation works with the selected Lua runtime.
- The test suite produces coverage data.
- The report identifies executed and unexecuted source lines.
- Excluded files and directories are handled as intended.
- Coverage output can be generated in the required format.

Do not treat a generated coverage report as proof of test quality. Coverage measures execution, not whether assertions are meaningful.

### 12.14 Optional native-code QA validation

GCOV, LCOV, and compiler sanitizers are outside the default Lua pack.

When developing native Lua modules or other C/C++ components, validate the selected native toolchain independently.

For coverage, verify that:

- Native code is compiled with the required coverage instrumentation.
- Test execution produces coverage data.
- GCOV can read the generated data.
- LCOV can collect and generate the intended report.

For sanitizers, verify that:

- The compiler supports the selected sanitizer.
- The native target is compiled and linked with the appropriate instrumentation.
- The test executable runs under the sanitizer.
- A controlled test fixture demonstrates that the sanitizer can detect the relevant class of error.

Do not assume every sanitizer is supported by every compiler, target, or Windows toolchain. Verify compatibility before making it part of a native-development workflow.

### 12.15 Optional LuaRocks validation

LuaRocks `3.13.0` is installed and configured for the standalone Lua `5.4.9` environment.

The following checks were observed:

| Check | Result |
|---|---|
| `luarocks --version` | PASS — reports `3.13.0` |
| LuaRocks configuration file | PASS — `config-5.4.lua` |
| Configured Make executable | PASS — WinLibs `mingw32-make.exe` |
| System rock tree | PASS — `%LOCALAPPDATA%\LuaRocks\5.4` |
| User rock tree | PASS — `%APPDATA%\LuaRocks` |
| User PATH entries | PASS — required entries already present |
| `luarocks --local install luacheck` | PASS — LuaCheck and its dependencies installed |
| `luacheck --version` | PASS — LuaCheck `1.2.0`, PUC-Rio Lua `5.4` |
| General native-rock build workflow | NOT VERIFIED |

The LuaRocks installer script's existing-installation path also passed. Its fresh-installation and `-Force` branches remain untested.

A successful version check alone is not sufficient to validate a package manager. For future native module projects, separately verify that the selected rock uses the intended Lua headers, libraries, compiler, architecture, and runtime DLL. The current record does not claim that a general native module build workflow has been tested.

### 12.16 Missing dependencies and formatter failure

These are required failure-path tests. Use an isolated environment or temporary `PATH` that excludes the relevant executable while preserving the tools needed to run the test. Do not uninstall tools from the main development environment.

**Missing LuaLS**

Check normal executable discovery:

```powershell
Get-Command lua-language-server -ErrorAction SilentlyContinue
```

In the isolated environment, verify that a missing executable is reported, LuaLS does not falsely appear operational, no automatic installation occurs, and unrelated configuration modules still load.

**Missing StyLua**

Check normal executable discovery:

```powershell
Get-Command stylua -ErrorAction SilentlyContinue
```

In the isolated environment, run:

```vim
:ConformInfo
:Format
```

Verify that the missing formatter is reported clearly, no automatic installation occurs, and unrelated configuration remains usable.

**Formatter failure**

Use a disposable Lua file. Record its original contents, introduce invalid or unformattable input, run `:Format`, inspect the output and log, and then restore or remove the fixture.

To inspect the usual Conform log location on Windows:

```powershell
Get-Content "$env:LOCALAPPDATA\nvim-data\conform.log" -Tail 100
```

The location may differ if Neovim's data directory has been customized.

For all three failure-path tests, record the actual result before marking the test passed. These tests are not yet verified by the current validation record.

## 13. Consolidated test status

| Test area | Status | Notes |
|---|---|---|
| StyLua repository check | PASS | `stylua --check .` |
| Lua syntax checker | PASS | 33 Lua files checked with the PowerShell `luac -p` loop; the earlier Neovim script reported 31 files |
| Headless configuration smoke test | PASS | Neovim 0.12.6 |
| Git whitespace check | PASS at last review | `git diff --check` passed before this documentation update; rerun after applying the updated file |
| LuaLS attachment and repository root | PASS | Interactive test |
| LuaLS diagnostics, hover, completion, and navigation | PASS | Interactive tests |
| Manual StyLua formatting through Conform | PASS | `:Format` |
| Standalone Lua workspace and diagnostics | PASS | Interactive test |
| Project-specific `.luarc.json` diagnostics | PASS | Configured and unconfigured globals distinguished |
| `.luarc.json` Lua 5.4 runtime override | NOT VERIFIED | Runtime application not independently confirmed |
| Tree-sitter mapping, parser, and highlighting | PASS | Interactive test |
| Standalone Lua 5.4.9 build and installation | PASS | Official source, WinLibs GCC, and external C API test |
| Standalone Lua PATH configuration | PASS | Persistent user PATH and fresh-session checks |
| LuaCheck repository CLI lint | PASS | LuaCheck 1.2.0; 33 files; zero warnings and errors; no `.luacheckrc` or editor integration |
| LuaCheck Lua 5.4 standard selection | NOT VERIFIED | Confirm supported standard name in installed release |
| LuaCheck Lua 5.4 attribute handling | NOT VERIFIED | `<const>` and `<close>` fixtures required |
| Busted optional integration | NOT ADOPTED | Preferred optional test framework; no project requirement established |
| LuaUnit optional integration | NOT ADOPTED | Alternative to Busted |
| LuaCov optional integration | NOT ADOPTED | No Lua coverage workflow established |
| GCOV/LCOV native coverage | OUT OF SCOPE | Separate native-development toolchain |
| ASan/TSan/UBSan | OUT OF SCOPE | Separate native-development toolchain |
| LuaRocks optional package management | PASS — installation and configuration | LuaRocks 3.13.0 configured for Lua 5.4.9; `luacheck` installed through the user rock tree |
| LuaRocks Lua 5.4 runtime alignment | PARTIALLY VERIFIED | Config file, Lua version, Make path, and rock trees checked; general native module build not tested |
| `luarocks-install.ps1` existing-installation path | PASS | Detected LuaRocks 3.13.0, configured Make, checked PATH, and completed verification |
| `luarocks-install.ps1` fresh-installation path | NOT VERIFIED | Requires a disposable environment without an existing LuaRocks installation |
| `luarocks-install.ps1 -Force` path | NOT VERIFIED | Force-reinstallation branch has not been exercised |
| Missing LuaLS behavior | NOT VERIFIED | Controlled failure test required |
| Missing StyLua behavior | NOT VERIFIED | Controlled failure test required |
| Formatter failure feedback | NOT VERIFIED | Controlled failure test required |
| Other operating systems | NOT VERIFIED | Windows is the recorded environment |

## 14. Completion criteria

The **default Lua language pack** can be marked complete when:

- LuaLS uses the shared native LSP architecture.
- Neovim-specific runtime and API settings work as intended.
- Standalone Lua projects and project-specific configuration behave correctly.
- StyLua is integrated through Conform and actual formatting succeeds.
- Tree-sitter parsing and highlighting work through the existing integration.
- Missing core executables are handled without automatic installation or unrelated startup failures.
- Formatter failures provide understandable feedback.
- Automated and interactive validation results are recorded.
- Dependency documentation accurately describes the core installation.

Optional capabilities have separate completion criteria:

- LuaCheck's repository CLI workflow is installed and validated. Broader standalone Lua 5.4 lint configuration and any editor integration require separate decisions and tests.
- Busted or LuaUnit must be selected and validated before a dedicated test-framework workflow is considered complete.
- LuaCov must be configured and tested against a real Lua test suite before coverage support is considered complete.
- LuaRocks is installed and configured for Lua 5.4.9, and LuaCheck was installed through it. General native-module compilation and the installer's fresh-installation and `-Force` paths remain unverified.
- Native coverage and sanitizer workflows must be validated against the selected compiler and native target before adoption.
- The standalone Lua 5.4.9 Windows runtime and its C development files are already installed and validated. This does not make them mandatory for the default profile.

Core LuaLS, StyLua, standalone-project, project-specific diagnostic, Tree-sitter, and standalone Lua 5.4.9 Windows runtime workflows have passed their recorded tests. The repository-wide LuaCheck CLI workflow also passes for all 33 Lua files. LuaRocks is installed and configured for the optional Lua 5.4.9 environment.

The document remains **in progress** until the outstanding core failure-path checks are completed or explicitly scoped out through a documented decision. Optional capabilities remain optional even when installed in the current development environment; their validation status is recorded separately.

## 15. Out of scope

- Automatic installation of LuaLS, StyLua, LuaCheck, Busted, LuaUnit, LuaCov, LuaRocks, or Tree-sitter parsers.
- Mason or another automatic tool installer.
- Making standalone Lua 5.4 a core dependency.
- Making GCC a core dependency.
- Making LuaRocks a core dependency.
- Making LuaCheck a core dependency.
- Making Busted or LuaUnit a core dependency.
- Making LuaCov a core dependency.
- Making GCOV, LCOV, ASan, TSan, or UBSan part of the default Lua pack.
- A new language-server framework or formatter dispatcher.
- Global suppression of undefined-global diagnostics.
- Format-on-save without a separate decision.
- A Lua-specific replacement for the existing project-root workflow.
- Replacing Neovim's embedded LuaJIT with standalone Lua 5.4.
- Making standalone Lua 5.4 the global runtime for every Lua project.

## References

### Neovim and editor integration

- [Neovim LSP documentation](https://neovim.io/doc/user/lsp.html)
- [Neovim Tree-sitter documentation](https://neovim.io/doc/user/treesitter.html)
- [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig)
- [LuaLS configuration documentation](https://luals.github.io/wiki/configuration/)
- [LuaLS settings reference](https://luals.github.io/wiki/settings/)
- [StyLua](https://github.com/JohnnyMorganz/StyLua)
- [Conform.nvim](https://github.com/stevearc/conform.nvim)
- [lazydev.nvim](https://github.com/folke/lazydev.nvim)

### Linting and testing

- [LuaCheck documentation](https://luacheck.readthedocs.io/en/stable/)
- [LuaCheck upstream project](https://github.com/lunarmodules/luacheck)
- [Busted documentation](https://lunarmodules.github.io/busted/)
- [Busted upstream project](https://github.com/lunarmodules/busted)
- [LuaUnit documentation](https://luaunit.readthedocs.io/)
- [LuaUnit upstream project](https://github.com/bluebird75/luaunit)
- [LuaCov upstream project](https://github.com/lunarmodules/luacov)

### Package management and runtime

- [LuaRocks documentation](https://luarocks.org/docs)
- [Lua 5.4.9 official source archive](https://www.lua.org/ftp/lua-5.4.9.tar.gz)
- [Lua 5.4 reference manual](https://www.lua.org/manual/5.4/)
- [WinLibs](https://winlibs.com/)

### Native-code QA

- [GCC instrumentation options](https://gcc.gnu.org/onlinedocs/gcc/Instrumentation-Options.html)
- [LCOV](https://github.com/linux-test-project/lcov)
- [AddressSanitizer](https://clang.llvm.org/docs/AddressSanitizer.html)
- [ThreadSanitizer](https://clang.llvm.org/docs/ThreadSanitizer.html)
- [UndefinedBehaviorSanitizer](https://clang.llvm.org/docs/UndefinedBehaviorSanitizer.html)

Revisit this document when the shared language architecture, supported Neovim baseline, standalone Lua toolchain, or Lua tooling requirements materially change.
