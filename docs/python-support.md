# Python Support

**Status:** Complete
**Stage:** 13 — Language Packs
**Test environment:** Windows, Neovim 0.12.6

Python support uses `uv` for project and environment management, `ty` for language-server functionality and type diagnostics, Ruff for linting and formatting, Neovim's native LSP client for editor integration, Conform for formatting integration, and the existing Tree-sitter installation for syntax highlighting.

The implementation follows the repository's native-first approach: tools are installed and managed outside Neovim, external executables are discovered through the environment, and plugin responsibilities remain explicit.

## 1. Architecture and decisions

| Concern | Decision |
|---|---|
| Python project and environment management | `uv` |
| Language server and type diagnostics | `ty` |
| Editor lint diagnostics | Ruff native language server |
| Native LSP client | Neovim built-in LSP |
| LSP server definitions | `nvim-lspconfig` |
| Standalone linting | Ruff (`ruff check .`) |
| Editor lint integration | Ruff native LSP (`ruff server`) |
| Formatting | Ruff through Conform's `ruff_format` formatter |
| Project configuration | `pyproject.toml` |
| Dependency lockfile | `uv.lock`, when maintained by the project |
| Syntax highlighting | Existing Tree-sitter installation |
| External-tool discovery | Environment and project virtual environment |
| Tool installation from Neovim | Not permitted |
| Mason | Not used |

The language pack must not install Python tools as a side effect of opening Neovim. Python tooling should be installed and managed through the user's external development workflow.

### Responsibility boundaries

The Python tooling has deliberately separated responsibilities:

- **uv:** Project, environment, dependency, and tool execution management.
- **Ty:** Python language-server functionality and type diagnostics.
- **Ruff LSP:** Editor-side lint diagnostics.
- **Ruff CLI:** Standalone linting.
- **Conform:** Formatting integration through `ruff_format`.
- **Tree-sitter:** Syntax parsing and highlighting.

Ty and Ruff run as separate LSP clients. Ruff's language server does not replace Ty, and Ty does not replace Ruff's linting functionality.

Ruff's LSP integration is used for diagnostics only. Formatting remains a separate Conform workflow.

## 2. Tool responsibilities

### `uv` — project and environment management

`uv` manages Python project workflows, virtual environments, dependencies, lockfiles, and execution of tools in the project environment.

Its responsibilities include:

- Creating and maintaining the project's Python virtual environment.
- Resolving and synchronizing project dependencies.
- Maintaining the lockfile when the project uses one.
- Running project tools in the intended environment.
- Providing a reproducible workflow across development machines.

Typical project commands include:

```powershell
uv --version
uv sync
uv run ruff check .
uv run ruff format --check .
```

Use `uv run` when a command should execute within the project's managed environment. The standalone `ruff check .` command remains the documented linting check when Ruff is already discoverable in the active environment.

The appropriate environment workflow depends on the repository's actual Python project metadata. Do not assume every Python directory already contains a `pyproject.toml`, `uv.lock`, or a managed virtual environment.

**Configuration authority:** `pyproject.toml` holds project metadata and tool configuration. `uv.lock`, when present, records resolved dependency versions for reproducibility. These files have different responsibilities and are not interchangeable.

### `ty` — language server

`ty` supplies Python language-server functionality and type diagnostics.

The Neovim configuration uses the maintained `ty` server definition provided by `nvim-lspconfig`, with Neovim's native LSP configuration and enablement APIs.

The upstream definition was inspected at:

```text
nvim-lspconfig/lsp/ty.lua
```

The installed definition specifies:

```lua
cmd = { "ty", "server" }
filetypes = { "python" }
root_markers = {
  "ty.toml",
  "pyproject.toml",
  "setup.py",
  "setup.cfg",
  "requirements.txt",
  ".git",
}
```

The language pack enables the server through:

```lua
vim.lsp.enable("ty")
```

The language pack must:

- Discover the `ty` executable through the active environment.
- Allow the project's virtual environment to supply the executable when appropriate.
- Avoid hardcoded installation paths.
- Avoid installing `ty` from Neovim.
- Produce diagnostics for deliberate source errors.
- Clear diagnostics after those errors are corrected.

The tested scenarios have validated server discovery, activation, attachment, diagnostics, project-root detection, definition, references, automatic completion, and hover.

Fresh-start attachment has also been verified.

### Ruff — native LSP linting

Ruff provides editor-side lint diagnostics through its native language server.

The integration uses the maintained Ruff server definition supplied by `nvim-lspconfig`.

The upstream definition was inspected at:

```text
nvim-lspconfig/lsp/ruff.lua
```

The installed definition specifies:

```lua
cmd = { "ruff", "server" }
filetypes = { "python" }
root_markers = {
  "pyproject.toml",
  "ruff.toml",
  ".ruff.toml",
  ".git",
}
```

The language pack enables Ruff through Neovim's native LSP API:

```lua
vim.lsp.enable("ruff")
```

Ruff and Ty are enabled independently. Both clients can attach to the same Python buffer.

Ruff's responsibilities include:

- Publishing lint diagnostics in Python buffers.
- Updating diagnostics when source code changes.
- Clearing diagnostics when reported violations are corrected.
- Following the project's Ruff configuration and applicable project root.

Ruff's standalone CLI remains available:

```powershell
ruff check .
```

When Ruff is managed by the project through `uv`, use:

```powershell
uv run ruff check .
```

**Editor lint integration is approved, implemented, and validated for the tested scenarios.**

The runtime validation confirmed that Ruff publishes an `F841` diagnostic for an unused local variable and clears that diagnostic after the source is corrected and saved.

No separate `ruff-lsp` package or `nvim-lint` integration is required.

### Ruff — formatting

Ruff formatting is integrated through Conform using the `ruff_format` formatter.

The formatter must be discoverable through the active environment. No executable path should be hardcoded.

The documented editor workflow is:

```vim
:Format
```

Formatting is explicit. Do not enable format-on-save or introduce an LSP formatting fallback without a separate decision.

Where the project manages Ruff with `uv`, validate the formatter in that same project environment as well.

**Formatting separation is an explicit architectural requirement:**

- Ruff LSP handles editor lint diagnostics.
- Conform invokes `ruff_format` for formatting.
- Ruff LSP must not become the formatting provider.
- No LSP formatting fallback is enabled.
- Format-on-save remains disabled by default.

The addition of Ruff LSP must not change the existing Conform configuration or transfer formatting responsibility to the language server.

### Tree-sitter — syntax highlighting

Python reuses the existing Stage 08 Tree-sitter setup.

The Python parser is installed in the shared Tree-sitter parser directory, and highlighting is enabled through the existing FileType autocmd. This language pack must not install another copy of Tree-sitter or introduce automatic parser installation.

The Python parser installation and highlighting have been verified in the current Windows environment.

## 3. Dependencies

| Dependency | Purpose | Validation status |
|---|---|---|
| Python | Python runtime | Python 3.14.7 used in the temporary project |
| `uv` | Project, environment, and dependency management | Version 0.13.6; temporary project workflow validated |
| `ty` | Language server and type diagnostics | Global version 0.0.92 and project-managed version 0.0.95 tested |
| Ruff | CLI linting, native LSP diagnostics, and formatting | Version 0.17.3; CLI, LSP diagnostics, and Conform formatting validated |
| Neovim 0.12+ | Native LSP and configuration APIs | Tested on Neovim 0.12.6 |
| `nvim-lspconfig` | Maintained `ty` and `ruff` server definitions | Installed definitions inspected and confirmed |
| Conform | Formatting integration | `ruff_format` workflow validated |
| `nvim-treesitter` | Python syntax highlighting | Parser and highlighting verified |

Install and update these tools outside Neovim using the chosen system or project-level workflow. The language pack should configure and use available tools rather than manage their installation.

## 4. Tool discovery

Check that the expected executables are available from PowerShell:

```powershell
Get-Command python
Get-Command uv
Get-Command ty
Get-Command ruff
```

Check their versions:

```powershell
python --version
uv --version
ty --version
ruff --version
```

A command may be available globally or through the project's virtual environment. The effective executable must match the intended project workflow.

Do not hardcode machine-specific paths in the Neovim configuration. If a tool is unavailable, report the missing dependency clearly and resolve it through the external installation workflow.

## 5. Project configuration

`pyproject.toml` is the authoritative location for project metadata and supported Python-tool configuration.

Depending on the project, it may contain:

- Python project metadata and dependency declarations.
- Ruff linting rules and formatting options.
- `ty` configuration supported by the installed version.
- Build-system configuration.

`uv.lock` records resolved dependency versions when the project maintains a lockfile. Use `uv sync` to synchronize the environment with the project's declared dependencies and lockfile.

Do not duplicate project settings unnecessarily in Neovim Lua. The language pack should integrate the tools, not replace their native configuration mechanisms.

Do not assume every Python project uses the same Python version, dependency groups, or environment layout. Validate commands against the actual project metadata.

## 6. Validation

### Completed checks

| Check | Status | Result |
|---|---|---|
| `uv` installation and discovery | Passed | Version 0.13.6 discovered |
| Temporary project initialization | Passed | Project metadata and virtual environment created |
| `uv sync` | Passed | Project environment synchronized |
| `uv run` tool execution | Passed | Ruff and Ty executed successfully |
| Project dependency installation | Passed | Ruff and Ty added as development dependencies |
| Lockfile synchronization | Passed | `uv sync --locked` recreated the environment successfully |
| Project-managed tool execution | Passed | Ruff 0.17.3 and Ty 0.0.95 executed from the project environment |
| `ty` executable discovery | Passed | Server executable discovered in tested scenarios |
| Upstream `ty` server definition | Passed | Installed `nvim-lspconfig` definition inspected |
| Upstream Ruff server definition | Passed | Installed `nvim-lspconfig` definition inspected |
| Native LSP activation and attachment | Passed | Ty and Ruff activated and attached to a Python buffer |
| Project-root detection | Passed | Ty reported the temporary project's root directory |
| Undefined-name diagnostics | Passed | Expected Ty diagnostic produced |
| Incompatible-type diagnostics | Passed | Expected Ty type diagnostic produced |
| Clean-source diagnostics | Passed | Ty diagnostics cleared after intentional errors were corrected |
| Automatic completion | Passed | Completion suggestions appeared while typing |
| Definition navigation (`gd`) | Passed | Jumped to the function definition |
| References (`gr`) | Passed | Reference navigation opened |
| Hover | Passed | `vim.lsp.buf.hover()` displayed the function signature |
| Ruff CLI linting | Passed | Standalone linting detected the expected violation |
| Ruff LSP activation and attachment | Passed | Ruff attached to the Python buffer |
| Ruff diagnostic publication | Passed | Ruff published an `F841` unused-variable diagnostic in Neovim |
| Ruff diagnostic clearing | Passed | Diagnostic disappeared after the unused variable was removed and the file was saved |
| Ty and Ruff coexistence | Passed | Both LSP clients attached to the same Python buffer |
| Fresh-start attachment | Passed | Both `ty` and `ruff` attached after a fresh Neovim startup |
| Ruff formatting through Conform | Passed | `ruff_format` workflow worked |
| Python Tree-sitter parser | Passed | Parser was installed and inspected successfully |
| Python Tree-sitter highlighting | Passed | Highlighting was active after restart and opening a Python file |

These results describe the tested scenarios. They do not establish that every Python project layout or environment has been validated.

The `uv` results came from a temporary validation project. They establish that the tested workflow works, not that every project in the repository already has the required metadata or dependency declarations.

### Out-of-scope checks

| Check | Status | Scope decision |
|---|---|---|
| Manual completion shortcut | Not configured | Shortcut configuration belongs to Stage 10, not the Python language pack |
| Python-specific smoke tests | Intentionally skipped | No Python-specific smoke suite is being added at this time |

Automatic completion has been validated. A manual completion shortcut is not a requirement for completing this language pack.

Python-specific smoke tests are intentionally excluded from the current validation scope. Their absence should not be represented as a passing test or as an implementation failure.

## 7. Validation procedure

Run these checks from the relevant project directory.

### A. Verify the Python toolchain

```powershell
python --version
uv --version
ty --version
ruff --version
```

Confirm that the expected commands resolve and that the Python interpreter and tools correspond to the intended environment.

### B. Validate the project environment

For a project that uses `uv` and has the appropriate project metadata:

```powershell
uv sync
uv run ruff check .
```

When the project maintains a lockfile and a reproducible environment is required:

```powershell
uv sync --locked
```

Confirm that synchronization uses the project's dependency declarations and lockfile when present. Do not create project metadata or a lockfile merely to make a test command pass.

### C. Validate standalone linting and formatting

Run Ruff linting:

```powershell
ruff check .
```

In Neovim, run:

```vim
:Format
```

Verify that formatting uses Ruff through Conform and does not depend on a hardcoded executable path.

Formatting must remain independent of Ruff's LSP diagnostic functionality.

### D. Validate LSP diagnostics

1. Open a Python file in the intended project.
2. Confirm that `ty` starts and attaches.
3. Confirm that Ruff starts and attaches.
4. Introduce an undefined name and verify the Ty diagnostic.
5. Introduce an incompatible type and verify the Ty diagnostic.
6. Introduce an unused local variable and verify the Ruff diagnostic.
7. Correct the intentional errors.
8. Confirm that the corresponding diagnostics clear.
9. Restart Neovim and verify that both servers attach again.

The diagnostic checks, project-root detection, initial attachment, diagnostic publication and clearing, and fresh-start attachment have passed in the tested scenarios.

### E. Validate Tree-sitter

Confirm that the Python parser can be inspected and that highlighting is active in a Python buffer. Reuse the existing Stage 08 configuration and parser installation.

### F. Run repository checks

Run the repository's applicable syntax, formatting, and existing smoke-test commands when preparing a commit.

Python-specific smoke tests are intentionally skipped for now. Record actual results rather than inferring success from the absence of visible errors.

## 8. Implementation boundaries

This language pack must preserve the following boundaries:

- `uv` manages the Python project environment and dependencies.
- `ty` provides language-server functionality and type diagnostics.
- Ruff provides standalone linting and editor lint diagnostics.
- Ruff's native LSP server must not take over formatting.
- Conform integrates formatting through `ruff_format`.
- Neovim's native LSP client handles language-server communication.
- `nvim-lspconfig` provides the maintained `ty` and Ruff server definitions.
- Tree-sitter reuses the existing parser infrastructure.
- External tools are installed and updated outside Neovim.
- Tool discovery must not rely on hardcoded machine-specific paths.
- Format-on-save remains disabled by default.
- LSP formatting fallback remains disabled.
- Python-specific smoke tests remain outside the current scope.
- Manual completion shortcut configuration remains outside Stage 13.

## 9. Completion criteria

Python support is complete because the following criteria have been validated:

- `uv` discovery and the intended project workflow work in the tested environment.
- `ty` discovers the correct executable, starts, attaches, and uses the intended project root.
- Ty diagnostics are produced for intentional errors and cleared when the source is corrected.
- Ruff discovers the correct executable and publishes editor diagnostics.
- Ruff diagnostics clear when the reported violations are corrected.
- Both LSP servers attach after a fresh Neovim startup.
- Automatic completion works.
- Ruff CLI linting and Conform formatting work with the intended environment.
- Formatting remains separate from LSP diagnostics, with formatting fallback disabled.
- Python Tree-sitter highlighting works through the existing shared configuration.
- Applicable tested repository and language workflows pass.

Ruff's editor linting integration has been approved and validated for the tested scenarios.

A Python-specific smoke-test suite is not a completion requirement under the current decision to skip it. Manual completion shortcut configuration is also not a Python language-pack completion requirement.

## References

- [uv documentation](https://docs.astral.sh/uv/)
- [ty documentation](https://docs.astral.sh/ty/)
- [Ruff documentation](https://docs.astral.sh/ruff/)
- [Neovim LSP documentation](https://neovim.io/doc/user/lsp.html)
- [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig)
- [Conform.nvim](https://github.com/stevearc/conform.nvim)
- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)

---

**Current status:** Python language support is complete for the defined Stage 13 scope. The tested `uv` project workflow, Ty language-server functionality and diagnostics, Ruff CLI linting, Ruff native LSP diagnostic publication and clearing, Ty and Ruff coexistence, fresh-start attachment, Ruff formatting through Conform, automatic completion, and Tree-sitter highlighting have passed. Formatting remains separate from LSP diagnostics. Python-specific smoke tests are intentionally skipped. Manual completion shortcut configuration belongs to Stage 10.
