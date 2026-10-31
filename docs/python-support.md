# Python Support

**Status:** In progress
**Stage:** 13 — Language Packs
**Test environment:** Windows, Neovim 0.12.6

Python support uses `uv` for project and environment management, `ty` for language-server diagnostics, Ruff for linting and formatting, Neovim's native LSP client for editor integration, Conform for formatting integration, and the existing Tree-sitter installation for syntax highlighting.

The implementation follows the repository's native-first approach: tools are installed and managed outside Neovim, external executables are discovered through the environment, and plugin responsibilities remain explicit.

## 1. Architecture and decisions

| Concern | Decision |
|---|---|
| Python project and environment management | `uv` |
| Language server and type diagnostics | `ty` |
| Native LSP client | Neovim built-in LSP |
| LSP server definitions | `nvim-lspconfig` |
| Standalone linting | Ruff (`ruff check .`) |
| Formatting | Ruff through Conform's `ruff_format` formatter |
| Project configuration | `pyproject.toml` |
| Dependency lockfile | `uv.lock`, when maintained by the project |
| Syntax highlighting | Existing Tree-sitter installation |
| External-tool discovery | Environment and project virtual environment |
| Tool installation from Neovim | Not permitted |
| Mason | Not used |
| Editor-side Ruff lint integration | Deferred pending a separate admission review |
| Automatic parser installation | Not configured by this language pack |

The language pack must not install Python tools as a side effect of opening Neovim. Python tooling should be installed and managed through the user's external development workflow.

## 2. Tool responsibilities

### `uv` — project and environment management

`uv` manages Python project workflows, virtual environments, dependencies, and execution of tools in the project environment.

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

**Configuration authority:** `pyproject.toml` holds project and tool configuration. `uv.lock`, when present, records resolved dependency versions for reproducibility. These files have different responsibilities and are not interchangeable.

### `ty` — language server

`ty` supplies Python language-server functionality and type diagnostics.

The Neovim configuration uses the maintained `ty` server definition provided by `nvim-lspconfig`, with Neovim's native LSP configuration and enablement APIs.

The language pack must:

- Discover the `ty` executable through the active environment.
- Allow the project's virtual environment to supply the executable when appropriate.
- Avoid hardcoded installation paths.
- Avoid installing `ty` from Neovim.
- Verify diagnostics using deliberate source errors and confirm that diagnostics clear after those errors are corrected.

The tested scenario has validated server discovery and activation, attachment, undefined-name diagnostics, and incompatible-type diagnostics. Further project-root and restart/startup validation remains open.

### Ruff — linting

Ruff is the standalone Python linting tool.

The baseline command is:

```powershell
ruff check .
```

When Ruff is managed by the project through `uv`, the project-aware alternative is:

```powershell
uv run ruff check .
```

Ruff's CLI linting has been validated. Editor-side Ruff lint integration is **not yet approved** and must not be treated as implemented.

Before admitting editor lint integration, review:

- How lint diagnostics are published and cleared.
- Whether the same diagnostics would be duplicated by another integration.
- How stale diagnostics behave after source changes.
- Whether the integration follows the project's root and environment.
- Whether the added integration provides enough value to justify its complexity.

### Ruff — formatting

Ruff formatting is integrated through Conform using the `ruff_format` formatter.

The formatter must be discoverable through the active environment. No executable path should be hardcoded.

The documented editor workflow is:

```vim
:Format
```

Formatting is explicit. Do not enable format-on-save or introduce an LSP formatting fallback without a separate decision.

Where the project manages Ruff with `uv`, validate the formatter in that same project environment as well.

### Tree-sitter — syntax highlighting

Python reuses the existing Stage 08 Tree-sitter setup.

The Python parser is installed in the shared Tree-sitter parser directory and highlighting is enabled through the existing FileType autocmd. This language pack must not install another copy of Tree-sitter or introduce automatic parser installation.

The Python parser's installation and highlighting have been verified in the current Windows environment.

## 3. Dependencies

| Dependency | Purpose | Validation status |
|---|---|---|
| Python | Python runtime | Verify the interpreter used by the project |
| `uv` | Project, environment, and dependency management | Include in Python tool checks |
| `ty` | Language server and type diagnostics | Discovery and diagnostics validated in the tested scenario |
| Ruff | Standalone linting and formatting | CLI linting and Conform formatting validated |
| Neovim 0.12+ | Native LSP and configuration APIs | Tested on Neovim 0.12.6 |
| `nvim-lspconfig` | Maintained `ty` server definition | Used by the configuration |
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

Check the `uv` version:

```powershell
uv --version
```

Check the other tools as appropriate:

```powershell
python --version
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
| `ty` executable discovery | Passed in the tested scenario | Server executable was discovered |
| LSP activation and attachment | Passed in the tested scenario | Server activated and attached |
| Undefined-name diagnostics | Passed | Expected diagnostic was produced |
| Incompatible-type diagnostics | Passed | Expected type diagnostic was produced |
| Clean-source diagnostics | **Passed** | Diagnostics cleared after intentional errors were corrected |
| Ruff CLI linting | Passed | Standalone linting worked |
| Ruff formatting through Conform | Passed | `ruff_format` workflow worked |
| Python Tree-sitter parser | Passed | Parser was installed and inspected successfully |
| Python Tree-sitter highlighting | Passed | Highlighting was active after restart and opening a Python file |

These results describe the tested scenarios; they do not establish that every Python project layout or environment has been validated.

### Remaining checks

| Check | Status | Purpose |
|---|---|---|
| Project-root behavior | Outstanding | Confirm `ty` uses the intended root for a real Python project |
| Restart/startup attachment | Outstanding | Confirm the server is discovered and attaches reliably after restarting Neovim |
| `uv` workflow | To be validated | Confirm tool discovery and project synchronization/execution against the intended Python project |
| Editor-side Ruff lint integration | Deferred | Complete the separate admission review before implementing it |

Do not mark the language pack complete until the required outstanding checks have passed and the decision on editor-side lint integration is documented.

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

Confirm that synchronization uses the project's dependency declarations and lockfile when present. Do not create project metadata or a lockfile merely to make a test command pass.

### C. Validate standalone linting and formatting

```powershell
ruff check .
```

In Neovim, run:

```vim
:Format
```

Verify that formatting uses Ruff through Conform and does not depend on a hardcoded executable path.

### D. Validate LSP diagnostics

1. Open a Python file in the intended project.
2. Confirm that `ty` starts and attaches.
3. Introduce an undefined name and verify the diagnostic.
4. Introduce an incompatible type and verify the diagnostic.
5. Correct the intentional errors.
6. Confirm that the diagnostics clear.
7. Restart Neovim and repeat the attachment check.

The clean-source diagnostic check has already passed. Repeat it only if a relevant change to the LSP configuration or diagnostic handling warrants regression testing.

### E. Validate Tree-sitter

Confirm that the Python parser can be inspected and that highlighting is active in a Python buffer. Reuse the existing Stage 08 configuration and parser installation.

### F. Run repository checks

Run the repository's applicable syntax, formatting, and smoke-test commands. Record actual results rather than inferring success from the absence of visible errors.

## 8. Implementation boundaries

This language pack must preserve the following boundaries:

- `uv` manages the Python project environment and dependencies.
- `ty` provides language-server functionality and type diagnostics.
- Ruff provides standalone linting and formatting.
- Conform integrates formatting into Neovim.
- Neovim's native LSP client handles language-server communication.
- `nvim-lspconfig` provides the maintained `ty` server definition.
- Tree-sitter reuses the existing parser infrastructure.
- External tools are installed and updated outside Neovim.
- Tool discovery must not rely on hardcoded machine-specific paths.
- Editor-side Ruff lint integration remains deferred until separately reviewed.

## 9. Completion criteria

Python support can be marked complete when:

- `uv` discovery and the intended project workflow are validated.
- `ty` reliably discovers the correct executable, starts, attaches, and uses the intended project root.
- Diagnostics are produced for intentional errors and cleared when the source is corrected.
- Startup and restart attachment are verified.
- Ruff linting and Conform formatting work with the intended environment.
- Python Tree-sitter highlighting works through the existing shared configuration.
- Relevant automated checks pass.
- The editor-side linting decision is documented, with no unapproved integration presented as implemented.

## References

- [uv documentation](https://docs.astral.sh/uv/)
- [ty documentation](https://docs.astral.sh/ty/)
- [Ruff documentation](https://docs.astral.sh/ruff/)
- [Neovim LSP documentation](https://neovim.io/doc/user/lsp.html)
- [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig)
- [Conform.nvim](https://github.com/stevearc/conform.nvim)
- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)

---

**Current status:** Core Python language-server diagnostics, clean-source diagnostic clearing, Ruff CLI linting, Ruff formatting, and Tree-sitter highlighting have passed their tested scenarios. Project-root behavior, restart/startup attachment, and the `uv` workflow remain to be validated. Editor-side Ruff lint integration remains deferred pending review.
