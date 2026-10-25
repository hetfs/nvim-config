# Dependencies

This document defines the external dependencies used by `nvim-config` and describes how the Windows dependency setup script checks, installs, and verifies them.

The project follows a native-first approach: Neovim provides the core editing functionality, while external executables and provider packages are installed separately from the Neovim configuration.

> **Approval is not installation.**

A plugin may use an external executable, but installing the plugin does not automatically install that executable. Plugin installation, external tool installation, language-server installation, and parser installation are separate responsibilities.

## Platform Support

The dependency setup script currently supports **Windows only**.

It uses WinGet to install missing applications and requires Microsoft App Installer to provide the `winget` command.

Other operating systems are outside the scope of `scripts/win-depend.ps1` and require their own dependency installation procedures.

## Requirements

### 1. Core Dependencies

These dependencies are checked by the Windows setup script.

| Dependency | Requirement | Purpose |
|---|---|---|
| Neovim | Version 0.12.0 or later | Runs the configuration and provides native editing features. |
| Git | Available on `PATH` | Provides version control and repository operations. |
| cURL | WinGet-managed executable | Provides command-line URL and network transfer functionality. |
| GNU tar | Bundled with Git for Windows | Provides archive extraction required by the Tree-sitter plugin workflow. |
| WinGet | Required on Windows | Installs missing applications using package identifiers. |

The script uses these WinGet package identifiers:

| Application | Package identifier |
|---|---|
| Neovim | `Neovim.Neovim` |
| Git | `Git.Git` |
| cURL | `cURL.cURL` |

Neovim is checked against the minimum supported version. If it is missing, the script attempts to install it. If the installed version is too old, the script attempts a WinGet upgrade and verifies the resulting version.

Git and cURL are checked for availability and successful version output. The script specifically verifies cURL through WinGet's Links directory rather than accepting an unrelated `curl.exe` elsewhere on `PATH`.

#### GNU tar

The script uses the GNU tar executable bundled with Git for Windows, normally located under Git's `usr\bin` directory.

It verifies that the executable exists, runs successfully, reports a GNU tar version, and is the executable resolved through `PATH` after configuration. The script places Git's `usr\bin` directory first on the current process's `PATH` to prioritize this verified executable.

This avoids requiring a separate GNU tar installation through WinGet.

### 2. Stage 07 Navigation and Search Dependencies

Stage 07 adds external command-line tools that support file discovery, content search, and fuzzy-finding workflows.

| Tool | WinGet package identifier | Purpose |
|---|---|---|
| `fd` | `sharkdp.fd` | Fast file and directory discovery. |
| `fzf` | `junegunn.fzf` | Command-line fuzzy finder used by the `fzf-lua` navigation plugin. |
| `rg` (ripgrep) | `BurntSushi.ripgrep.MSVC` | Fast recursive content search used by compatible search workflows. |

These are **external executables**, not Neovim plugins. The corresponding Neovim plugins are configured separately through the project's native `vim.pack` workflow.

#### `fd`

`fd` provides fast file and directory discovery. It supports file-finding workflows that can benefit from a dedicated file-search executable, including compatible navigation workflows using Snacks and other tools.

The Windows setup script checks for the executable and attempts to install it through WinGet if it is missing. After installation, the executable must be available to the current shell environment.

The presence of `fd` does not prove that every picker or file-navigation workflow is configured to use it.

#### `fzf`

`fzf` is the external fuzzy-finder executable used by `fzf-lua`.

Installing the `fzf-lua` Neovim plugin does not, by itself, install the `fzf` executable. The Windows setup script therefore checks for the executable and attempts to install it through WinGet if necessary.

The `fzf-lua` mappings provide an independent set of configured file-finding, content-search, buffer-finding, and picker-resume workflows.

#### Ripgrep (`rg`)

Ripgrep is a fast recursive text-search utility. It searches file contents and supports content-search workflows used by compatible Neovim pickers and search interfaces.

The Windows setup script checks for `rg.exe` or `rg` on the current `PATH`. If neither command is available, it attempts to install ripgrep through WinGet using the package identifier `BurntSushi.ripgrep.MSVC`. It then verifies the executable by checking its version output.

Ripgrep provides the search engine for content-search workflows; it is not a file-discovery or fuzzy-finding replacement for `fd` or `fzf`.

The tools have distinct responsibilities:

- **`fd`** discovers files and directories.
- **`rg` (ripgrep)** searches text inside files.
- **`fzf`** provides interactive fuzzy selection.
- **Snacks Picker and `fzf-lua`** provide Neovim interfaces and workflows that can use these external tools.

The availability of `rg` does not, by itself, verify that a picker is configured correctly or that its mappings and interactive search behavior work as intended.

#### Relationship to Stage 07

Stage 07 uses multiple navigation tools with separate responsibilities:

- **Snacks Picker and Explorer** provide file discovery, content search, buffer selection, and file browsing.
- **`fzf-lua`** provides an independent set of fuzzy-finding workflows backed by the external `fzf` executable.
- **Flash** provides jump and search navigation inside Neovim.
- **`mini.nvim` modules** provide editing features such as text-object selection, surrounding operations, and movement.

The external `fd`, `fzf`, and `rg` executables complement these plugins. They do not replace the plugins, and not every Stage 07 feature depends on all three executables.

The availability of these commands alone does not verify that plugin setup, keymaps, or interactive navigation behave correctly. Those are tested separately through the project's smoke tests and interactive validation procedures.

### 3. Stage 08 Tree-sitter Dependencies

Stage 08 introduces Tree-sitter-based syntax parsing and highlighting through the `nvim-treesitter` plugin.

The Windows setup script checks the external prerequisites needed to install and build parsers.

| Dependency | WinGet package identifier | Requirement | Purpose |
|---|---|---|---|
| WinLibs GCC/G++ | `BrechtSanders.WinLibs.POSIX.UCRT` | GCC and G++ executables available | Compiles parser components that require a C compiler. |
| Tree-sitter CLI | `tree-sitter.tree-sitter-cli` | Version 0.26.1 or later | Provides the command-line interface for parser-related workflows. |
| GNU tar | Bundled with `Git.Git` | Verified GNU tar executable | Supports archive extraction for plugin and parser workflows. |
| cURL | `cURL.cURL` | Verified executable | Supports network downloads. |

#### WinLibs GCC/G++

The script locates the installed WinLibs POSIX UCRT toolchain in WinGet's package directory. It verifies that both `gcc.exe` and `g++.exe` exist, prioritizes the selected toolchain's `mingw64\bin` directory on the current process's `PATH`, and checks that both executables resolve to the expected files and return valid version output.

The script explicitly sets the `CC` environment variable to the verified GCC executable:

```powershell
$env:CC = $gccPath
```

This helps Tree-sitter parser build processes select the intended compiler instead of an unrelated compiler found elsewhere on the system.

The setting is **process-scoped**. It is available to the running PowerShell session and its child processes, but it is not persisted as a Windows user or system environment variable. Run the setup script again in a new PowerShell session when the compiler environment needs to be configured there.

#### Tree-sitter CLI

The script checks whether the `tree-sitter` executable is available. If it is missing, the script attempts to install it through WinGet.

It then reads the CLI version and verifies that it meets the minimum requirement of `0.26.1`.

The CLI is an external development dependency. Installing it does not install the Neovim plugin or guarantee that every parser can be compiled successfully.

#### Neovim plugin and parser installation

The Neovim plugin is managed separately through the project's native `vim.pack` workflow.

The plugin setup configures the parser and query installation directory under Neovim's data directory. Parser installation and highlighting are separate from the Windows dependency setup script.

Stage 08 initially enables native Tree-sitter highlighting for Lua. The configuration uses `vim.treesitter.start()` when a Lua buffer's `FileType` event fires.

The Windows setup script does **not** install Neovim parsers, configure highlighting, or test parser queries. Those behaviors must be validated inside Neovim.

Tree-sitter's presence also does not imply that the project has enabled Tree-sitter-based indentation, folding, or other language-specific workflows. Such features remain separate configuration decisions.

### 4. Stage 09 — LSP and Lua Development Dependencies

Stage 09 introduces native Language Server Protocol (LSP) configuration and Lua development support. Neovim's built-in LSP client remains responsible for configuring and activating language servers, while plugins provide maintained server definitions and additional development context.

#### Lua language server

- **LuaLS (`lua-language-server`)** — external executable used by Neovim's native LSP client for Lua diagnostics and language features.
- The executable must be available on `PATH`.
- `lazydev.nvim` improves LuaLS awareness of Neovim and installed Lua libraries; it does not install or manage LuaLS.
- Server installation and updates remain the responsibility of the system package manager, `mise`, or another explicitly chosen external tool manager.
- Mason is not part of the default configuration.

Neovim's native `vim.lsp.config()` and `vim.lsp.enable()` APIs configure and activate the language server. The `nvim-lspconfig` plugin supplies maintained server definitions; it does not install the LuaLS executable.

Python language-server dependencies remain outside Stage 09 and are deferred to Stage 13.

The Windows dependency setup script does not install or manage LuaLS. Its availability and actual attachment to Lua buffers must be verified separately from the script's dependency checks.

### 5. Stage 12 — Git, Project Navigation, and Sessions

Stage 12 adds Git integration, project root detection and navigation, and explicit session management.

These workflows combine Neovim plugins, native Neovim APIs, Git, and an optional external terminal application. They do not all require separate external executables.

| Component | Type | External requirement | Purpose |
|---|---|---|---|
| Gitsigns | Neovim plugin | Git and a Git repository for Git-based workflows | Displays Git change indicators and provides hunk operations, blame, and diff workflows. |
| `project.nvim` | Neovim plugin | Git metadata for Git-based root detection; other root markers may also apply | Detects project roots and supports project navigation. |
| `mini.sessions` | Module from the shared `mini.nvim` plugin | No additional executable required by the documented session workflow | Saves, restores, and deletes sessions explicitly. |
| Lazygit | Optional external executable | `lazygit` available on `PATH` to launch it | Provides a terminal-based Git interface when installed. |

#### Git and Gitsigns

Git is a core dependency. Gitsigns uses Git repository information to display changes and provide Git-related buffer operations.

The Gitsigns plugin does not install Git. If Git is unavailable or a buffer is not associated with a suitable repository, Git-based functionality may not be available as expected.

The current configuration registers buffer-local hunk mappings through the central keymap module:

- `<leader>ghs` — stage hunk.
- `<leader>ghr` — reset hunk.
- `<leader>ghp` — preview hunk.
- `<leader>ghb` — blame line.
- `<leader>ghd` — diff buffer.

These mappings require Gitsigns to be installed and attached to the buffer. The presence of Git and Gitsigns alone does not prove that each interactive workflow works correctly.

#### Project root detection

`project.nvim` provides project root detection and navigation. It can use Git-related markers and other configured root indicators to identify projects.

The plugin does not install Git or other external tools. Git-based root detection relies on the repository metadata and Git availability required by the chosen detection workflow.

Project root detection is distinct from automatic working-directory changes. The current configuration disables automatic directory changes, so root detection should not be interpreted as a guarantee that Neovim's working directory changes whenever a project is detected.

The plugin's root detection and navigation behavior must be verified inside Neovim.

#### Session management

Session management uses `mini.sessions`, which is a module of the existing shared `mini.nvim` installation. It does not require a second `mini.nvim` installation or an additional command-line executable for the documented workflow.

The current configuration uses explicit save, restore, and delete operations:

- `<leader>qw` — select a session and save it.
- `<leader>qs` — select a session and restore it.
- `<leader>qd` — select a session and delete it.

Automatic session reads and writes are disabled. Session management is separate from Git operations and project root detection: a saved session records editor state according to `mini.sessions` behavior, not a promise that external tools or project dependencies are installed.

#### Optional Lazygit

Lazygit is an optional external terminal application, not a Neovim plugin and not a core dependency.

The Windows dependency setup script does not install or verify Lazygit unless that behavior is explicitly added to the script in a future change. Users who want to launch Lazygit from Neovim must install it separately and make the `lazygit` executable available on `PATH`.

Any Neovim mapping that launches Lazygit must check whether the executable is available before attempting to run it. If it is missing, the configuration should show a clear warning rather than failing silently.

The presence of Git does not imply that Lazygit is installed. Likewise, installing Gitsigns or `project.nvim` does not install Lazygit.

### 6. Neovim Providers

The script installs or verifies the Node.js and Python providers.

| Provider | Runtime | Provider package | Installation method |
|---|---|---|---|
| Node.js | Node.js | `neovim` | Global npm package |
| Python | Python 3 | `pynvim` | pip |

#### Node.js provider

The script checks for an existing Node.js runtime and reuses it when available. If Node.js is missing, it installs it through WinGet.

It then checks for npm and verifies whether the global `neovim` package is installed. If the package is missing, the script installs it globally and verifies the result.

The WinGet package identifier for Node.js is `OpenJS.NodeJS`.

#### Python provider

The script prefers Python 3.14 through the Windows Python launcher. If that runtime is unavailable, it accepts another working Python 3 interpreter. It can also fall back to a `python` executable that reports a Python 3 version.

The WinGet package identifier used when Python is missing is `Python.Python.3.14`.

The script checks whether pip is available and attempts to bootstrap it with `ensurepip` if necessary. It then checks whether `pynvim` can be imported by the selected interpreter, installs or upgrades the package if needed, and verifies the final import.

The provider package is installed into the selected Python interpreter's environment. The script does not write provider paths into Neovim configuration files or persist provider-related environment variables.

### 7. Development Tools

| Tool | WinGet package identifier | Purpose |
|---|---|---|
| ShellCheck | `koalaman.shellcheck` | Validates shell scripts. |

ShellCheck is checked independently from the core dependencies and provider setup. If it is missing, the script attempts to install it through WinGet and verifies its version output.

ShellCheck is a development tool rather than a runtime requirement for Neovim itself.

## Installation and Verification

Run the Windows dependency setup script from the repository root in PowerShell:

```powershell
.\scripts\win-depend.ps1
```

The script:

1. Confirms that it is running on Windows.
2. Ensures Windows System32 is available on the current process's `PATH`.
3. Checks that WinGet is available.
4. Checks and verifies the core dependencies, including Neovim, Git, cURL, and Git's bundled GNU tar.
5. Checks and verifies the Stage 07 navigation and search executables, `fd`, `fzf`, and `rg`.
6. Sets up and verifies the Node.js provider.
7. Sets up and verifies the Python provider.
8. Locates and verifies the WinLibs GCC/G++ toolchain and configures `CC` for the current process.
9. Checks and verifies the Tree-sitter CLI.
10. Checks and verifies ShellCheck.
11. Reports failures and returns an appropriate exit code.

The script reuses existing installations when they satisfy its checks and installs missing dependencies as needed. It continues with independent setup steps when an individual step fails, then summarizes failures at the end.

**The script's current scope does not include installing LuaLS or Lazygit.** Those tools must be managed separately if required. Neovim plugins, language servers, and Tree-sitter parsers are also outside the Windows script's installation responsibilities unless explicitly implemented there.

A successful exit code indicates that the script's dependency and provider checks completed successfully. It does **not** prove that every Neovim feature, parser, or interactive workflow works correctly.

### Recommended verification commands

After running the setup script, verify the development tools in the same PowerShell session:

```powershell
rg --version
fd --version
fzf --version
gcc --version
g++ --version
tree-sitter --version
tar --version
$env:CC
```

The `CC` value should point to the verified WinLibs `gcc.exe`. The Tree-sitter CLI should report version `0.26.1` or later.

To validate the Neovim configuration separately, run the project's applicable formatting and syntax checks:

```powershell
stylua --check .
nvim --headless -u NONE -l scripts/check-syntax.lua
git diff --check
```

Parser installation and actual highlighting should be checked independently inside Neovim. Content search, file discovery, and fuzzy-finding workflows should likewise be validated through their configured Neovim interfaces.

For Stage 09, also verify that `lua-language-server` is available on `PATH`, that the Lua language server attaches to Lua buffers, and that diagnostics and other configured LSP features work as expected. Merely having the executable or a registered LSP configuration does not prove that the server has attached successfully.

For Stage 12, verify Git hunk workflows in a Git repository, project root detection and navigation, and explicit session save/restore/delete behavior. If Lazygit integration is enabled, verify both the installed-executable path and the missing-executable warning.

## Environment and Side Effects

The setup script is designed to avoid changing the Neovim configuration itself.

- It does not rewrite Neovim configuration files.
- It does not remove existing Neovim configuration or data.
- It does not persist changes to the Windows `PATH` environment variable.
- It refreshes or adjusts `PATH` only for the current PowerShell process and its child processes.
- It sets `CC` to the verified WinLibs GCC executable for the current process and its child processes.
- It reuses working applications and provider packages when possible.
- It may install or upgrade applications and packages when required.

The script prioritizes Git's bundled GNU tar and the selected WinLibs compiler directory on the current process's `PATH`. These changes are not permanent Windows environment modifications.

If WinGet installs one or more applications, already-running applications may need to be restarted to pick up the updated environment.

The script also ensures that Windows System32 is available as a fallback on the current process's `PATH`. It avoids adding a duplicate entry if the directory is already present.

## Optional Providers

Perl and Ruby are not installed by the Windows dependency setup script. The current Neovim configuration disables these providers because they are not required by the project.

They should not be treated as dependencies unless a future project decision introduces a feature that requires them.

Lazygit is also optional. It is an external terminal application and is not installed by Gitsigns, `project.nvim`, or the Windows dependency setup script.

## Failure Handling

The script uses explicit checks and reports failures for required setup steps.

Examples include:

- WinGet is unavailable.
- Neovim is below the minimum supported version.
- An executable cannot be found after installation.
- GNU tar cannot be verified or resolved to Git's bundled executable.
- The WinLibs toolchain or either compiler executable cannot be located or verified.
- The Tree-sitter CLI is missing, cannot be verified, or is below the minimum supported version.
- A runtime or provider package fails verification.
- A package manager returns a nonzero exit code.

Individual setup failures are recorded, and the script attempts to continue with independent steps. If any required step fails, the script exits with code `1`; otherwise, it exits with code `0`.

When setup fails, resolve the reported issue and rerun:

```powershell
.\scripts\win-depend.ps1
```

External tools outside the script's scope, such as LuaLS and optional Lazygit, must be installed and verified separately.

## Dependency Policy

- Prefer Neovim's built-in functionality where it meets project requirements.
- Keep external executables and language-provider packages separate from the Neovim configuration.
- Install external tools through the operating system or its package manager rather than managing them as Neovim plugins.
- Treat plugin installation, parser installation, and external executable installation as separate responsibilities.
- Verify dependencies instead of assuming that an installed package is correctly available.
- Keep compiler and environment configuration process-scoped unless a deliberate project decision requires persistence.
- Avoid installing optional runtimes unless an accepted feature requires them.
- Document navigation and search tools according to their actual workflow dependencies: `fd` for file discovery, `rg` for content search, and `fzf` for fuzzy selection.
- Document Tree-sitter's compiler, CLI, and archive-extraction prerequisites separately from Neovim parser and highlighting configuration.
- Keep LSP server executables externally managed; `nvim-lspconfig` supplies server definitions, and `lazydev.nvim` supplies Lua development context rather than installing or managing LuaLS.
- Keep project root detection distinct from automatic working-directory changes.
- Treat Git as a core external dependency for Git-based workflows, not as something Gitsigns installs.
- Keep Lazygit optional and externally managed. Do not imply that Git or any Neovim plugin installs it.
- Update this document when the setup script's requirements, package identifiers, or verification behavior change.
