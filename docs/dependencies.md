# Dependencies

This document defines the external dependencies used by `nvim-config` and describes how the Windows dependency setup script checks, installs, and verifies them.

The project follows a native-first approach: Neovim provides the core editing functionality, while external executables and provider packages are installed separately from the Neovim configuration.

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
| WinGet | Required on Windows | Installs missing applications using package identifiers. |

The script uses these WinGet package identifiers:

| Application | Package identifier |
|---|---|
| Neovim | `Neovim.Neovim` |
| Git | `Git.Git` |
| cURL | `cURL.cURL` |

Neovim is checked against the minimum supported version. If it is missing, the script attempts to install it. If the installed version is too old, the script attempts a WinGet upgrade and verifies the resulting version.

Git and cURL are checked for availability and successful version output. The script specifically verifies cURL through WinGet's Links directory rather than accepting an unrelated `curl.exe` elsewhere on `PATH`.

### 2. Stage 07 Navigation Dependencies

Stage 07 adds external command-line tools that support file discovery and fuzzy-finding workflows.

| Tool | WinGet package identifier | Purpose |
|---|---|---|
| `fd` | `sharkdp.fd` | Fast file and directory discovery, including workflows that use the Snacks navigation tools. |
| `fzf` | `junegunn.fzf` | Command-line fuzzy finder used by the `fzf-lua` navigation plugin. |

These are **external executables**, not Neovim plugins. The corresponding Neovim plugins are configured separately through the project's native `vim.pack` workflow.

#### `fd`

`fd` provides fast file and directory discovery. It supports file-finding workflows that can benefit from a dedicated file-search executable.

The Windows setup script checks for the executable and attempts to install it through WinGet if it is missing. After installation, the executable must be available to the current shell environment.

#### `fzf`

`fzf` is the external fuzzy-finder executable used by `fzf-lua`.

Installing the `fzf-lua` Neovim plugin does not, by itself, install the `fzf` executable. The Windows setup script therefore checks for the executable and attempts to install it through WinGet if necessary.

The `fzf-lua` mappings provide the configured file-finding, content-search, buffer-finding, and picker-resume workflows.

#### Relationship to Stage 07

Stage 07 uses multiple navigation tools with separate responsibilities:

- **Snacks Picker and Explorer** provide file discovery, content search, buffer selection, and file browsing.
- **`fzf-lua`** provides an independent set of fuzzy-finding workflows backed by the external `fzf` executable.
- **Flash** provides jump and search navigation inside Neovim.
- **`mini.nvim` modules** provide editing features such as text-object selection, surrounding operations, and movement.

The external `fd` and `fzf` executables complement these plugins. They do not replace the plugins or make every Stage 07 feature dependent on both executables.

The availability of these commands alone does not verify that plugin setup, keymaps, or interactive navigation behave correctly. Those are tested separately through the project's smoke tests and interactive validation procedures.

### 3. Neovim Providers

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

### 4. Development Tools

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
4. Checks and verifies the core dependencies.
5. Checks and verifies the Stage 07 navigation executables, `fd` and `fzf`.
6. Sets up and verifies the Node.js provider.
7. Sets up and verifies the Python provider.
8. Checks and verifies ShellCheck.
9. Reports any failures and returns an appropriate exit code.

The script reuses existing installations when they satisfy its checks and installs missing dependencies as needed. It continues with independent setup steps when an individual step fails, then summarizes failures at the end.

A successful exit code indicates that the script's dependency and provider checks completed successfully. It does **not** prove that every Neovim feature or interactive workflow works correctly.

## Environment and Side Effects

The setup script is designed to avoid changing the Neovim configuration itself.

- It does not rewrite Neovim configuration files.
- It does not remove existing Neovim configuration or data.
- It does not persist changes to the Windows `PATH` environment variable.
- It refreshes `PATH` only for the current PowerShell process and its child processes.
- It reuses working applications and provider packages when possible.
- It may install or upgrade applications and packages when required.

If WinGet installs one or more applications, already-running applications may need to be restarted to pick up the updated environment.

The script also ensures that Windows System32 is available as a fallback on the current process's `PATH`. It avoids adding a duplicate entry if the directory is already present.

## Optional Providers

Perl and Ruby are not installed by the Windows dependency setup script. The current Neovim configuration disables these providers because they are not required by the project.

They should not be treated as dependencies unless a future project decision introduces a feature that requires them.

## Failure Handling

The script uses explicit checks and reports failures for required setup steps.

Examples include:

- WinGet is unavailable.
- Neovim is below the minimum supported version.
- An executable cannot be found after installation.
- A runtime or provider package fails verification.
- A package manager returns a nonzero exit code.

Individual setup failures are recorded, and the script attempts to continue with independent steps. If any required step fails, the script exits with code `1`; otherwise, it exits with code `0`.

When setup fails, resolve the reported issue and rerun:

```powershell
.\scripts\win-depend.ps1
```

## Dependency Policy

- Prefer Neovim's built-in functionality where it meets project requirements.
- Keep external executables and language-provider packages separate from the Neovim configuration.
- Install external tools through the operating system or its package manager rather than managing them as Neovim plugins.
- Treat plugin installation and external executable installation as separate responsibilities.
- Verify dependencies instead of assuming that an installed package is correctly available.
- Avoid installing optional runtimes unless an accepted feature requires them.
- Keep navigation tools such as `fd` and `fzf` documented with their actual workflow dependencies.
- Update this document when the setup script's requirements, package identifiers, or verification behavior change.
