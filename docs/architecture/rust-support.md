# Rust Support

**Stage:** 13 – Language Packs
**Pack:** `rust`
**Tier:** Core
**Status:** Implementation complete; validation passed; Stage 13 accepted

This document records the Rust language-pack architecture, implementation, and validation results for the `nvim-config` project.

The implementation supports standalone Rust crates and Cargo workspaces. It uses `rust-analyzer` for language intelligence, `rustfmt` through Conform for formatting, the existing Tree-sitter integration, and a native `:Cargo` command for common Cargo workflows.

This is not the Rust toolchain installation guide. The installation guide owns Rustup, the compiler, linker, Windows SDK, and operating-system prerequisites. This document owns the Neovim-side Rust integration.

Keep this document separate from `rust-win-install.md`, which documents Windows toolchain installation, and the user-facing Rust language-pack documentation.

The implementation follows the project's native-first architecture. It reuses Neovim's built-in LSP client, existing language registry, Conform integration, Tree-sitter infrastructure, terminal buffers, and centralized keymaps. It introduces no new plugin dependency and performs no tool installation during Neovim startup.

## 1. Goals and design principles

- **Native-first:** Use `vim.lsp.config`, `vim.lsp.enable`, native filetype detection, Tree-sitter, and terminal buffers.
- **Language intelligence:** Use `rust-analyzer` for completion, hover, navigation, references, rename, code actions, and diagnostics.
- **External formatting:** Use `rustfmt` through the existing Conform integration.
- **Manual formatting:** Preserve the existing `:Format` workflow. Format-on-save remains disabled by default.
- **Single formatting authority:** Conform owns Rust formatting. Rust-analyzer formatting capabilities are disabled for Rust buffers.
- **Optional Clippy:** Allow rust-analyzer to run Clippy when the optional component is installed and enabled.
- **Workspace awareness:** Resolve Cargo workspace roots so workspace members share one rust-analyzer project root.
- **Cross-platform:** Support Windows, Linux, and macOS without constructing shell-specific command strings.
- **Existing ownership:** Reuse the current language registry, formatter resolver, LSP lifecycle, Tree-sitter setup, and centralized keymaps.
- **Testability:** Keep root resolution and configuration behavior independently testable.
- **Explicit dependencies:** Detect missing external tools and report actionable diagnostics. Never install tools during startup.

## 2. Scope and non-goals

### In scope

- `rust-analyzer` configuration and activation through the native LSP API.
- Rust filetype and Tree-sitter parser registration.
- `rustfmt` formatting through Conform.
- Cargo workspace and standalone crate root resolution.
- A native `:Cargo` command for common Cargo workflows.
- Optional Clippy integration.
- Offline configuration tests and real-toolchain integration tests.

### Deferred or out of scope

- Rust toolchain installation and operating-system prerequisites.
- CodeLLDB and DAP setup; debugging belongs to Stage 14.
- A new Rust-specific plugin.
- Automatic tool installation or updates.
- A second TOML parser or formatter.
- Native inlay-hint configuration.
- Experimental rust-analyzer extension commands.
- Full Cargo manifest parsing in Lua.

## 3. Component inventory

| Concern | Component | Ownership |
|---|---|---|
| Compiler | `rustc` | External Rust toolchain |
| Build and package manager | `cargo` | External Rust toolchain |
| Language server | `rust-analyzer` | External tool |
| LSP server definitions | `nvim-lspconfig` | Existing plugin; definitions only |
| LSP configuration and activation | `vim.lsp.config`, `vim.lsp.enable` | Neovim native |
| Formatter | `rustfmt` | External Rust toolchain |
| Formatter integration | Conform | Existing plugin |
| Rust parser | `rust` | Existing Tree-sitter infrastructure |
| Cargo manifest parser | Existing TOML support | Existing data-language pack |
| Optional linter | Clippy through rust-analyzer | Optional external component |
| Build and test terminal | Neovim terminal and job API | Neovim native |
| Debugging | CodeLLDB and DAP | Stage 14 |

`Cargo.toml` and `Cargo.lock` are TOML files. The existing data-language pack owns TOML parsing and formatting. Rust support must not register a second TOML parser or formatter.

## 4. File ownership and integration boundaries

The following paths describe the implementation.

```text
lua/
├── langs/
│   ├── init.lua
│   └── rust.lua
└── config/
    ├── languages.lua
    ├── autocmds.lua
    ├── format.lua
    ├── lsp.lua
    ├── rust.lua
    └── keymaps.lua

scripts/
├── test-rust-clippy.lua
├── test-rust-edition.lua
├── test-rust-lsp.lua
├── test-rust-parser.lua
└── test-rust-roots.lua

docs/
└── architecture/
    ├── rust-support.md
    └── rust-win-install.md
```

| File | Responsibility |
|---|---|
| `lua/langs/rust.lua` | Rust pack metadata, Cargo root resolution, rust-analyzer configuration, and Rust-specific LSP behavior |
| `lua/langs/init.lua` | Existing language-pack registry and setup lifecycle |
| `lua/config/languages.lua` | Language-pack enablement and optional Rust Clippy setting |
| `lua/config/format.lua` | Existing Conform configuration and Rust formatter override |
| `lua/config/autocmds.lua` | Rust buffer-local editor settings and Rust keymap registration |
| `lua/config/rust.lua` | Native `:Cargo` command |
| `lua/config/lsp.lua` | Shared LSP attachment behavior |
| `lua/config/keymaps.lua` | Centralized LSP and Rust keymaps |
| `lua/plugins/treesitter.lua` | Existing parser installation and highlighting lifecycle |
| `scripts/test-rust-*.lua` | Focused Rust configuration and integration tests |

Do not create a second language registry, plugin-loading path, or formatter lifecycle for Rust.

### 4.1 Preserve existing shared behavior

Rust configuration preserves the existing Stage 09 LSP behavior:

- Shared `LspAttach` handling continues to call `require("config.keymaps").lsp(event.buf)`.
- Centralized LSP keymaps and diagnostics configuration remain unchanged.
- The language registry retains its existing setup and metadata contracts.
- Conform retains its existing formatter resolver and precedence rules.
- Format-on-save remains disabled by default.
- LSP formatting fallback remains disabled by default.

Rust-specific behavior must not replace shared behavior.

## 5. External tool contract

The Rust language pack expects the external toolchain to be installed and available in the environment from which Neovim is launched.

| Executable or component | Requirement | Used for |
|---|---|---|
| `rust-analyzer` | Required | Language server |
| `rustfmt` | Required | Formatting |
| `cargo` | Required | Build, check, test, run, and package workflows |
| `rustc` | Required through the Rust toolchain | Compilation |
| `rust-src` | Recommended | Standard-library source navigation |
| Clippy | Optional | Additional diagnostics |

The separate Rust installation guide owns provisioning and operating-system-specific setup.

The pack may check executable availability and report missing requirements. It must not invoke `rustup component add`, download binaries, modify PATH, or install prerequisites automatically.

### 5.1 Runtime diagnostics

Distinguish between:

- **Configuration validation:** Checks Lua configuration and helper behavior without launching Rust tools.
- **Toolchain validation:** Checks that required executables are discoverable.
- **Integration validation:** Launches rust-analyzer, rustfmt, and Cargo against real projects.

An offline configuration test must not fail solely because an external executable is unavailable.

## 6. Rust language-pack implementation

### 6.1 Pack metadata

Rust is registered through the existing language registry.

The Rust module declares:

- Formatter metadata for `rustfmt`.
- Parser metadata mapping the `rust` filetype to the `rust` Tree-sitter parser.

The registry remains responsible for collecting metadata and invoking enabled pack setup.

Do not add a separate Rust activation mechanism or introduce metadata fields that the registry does not consume.

The current language configuration enables the Rust pack:

```lua
packs = {
    rust = true,
}
```

Optional Clippy configuration is controlled separately:

```lua
tools = {
    rust_clippy = false,
}
```

### 6.2 Project-root detection

The Rust root resolver supports:

1. Standalone crates containing `Cargo.toml`.
2. Member crates inside Cargo workspaces.
3. Projects described by `rust-project.json`.
4. Files outside recognized Rust projects.

For Cargo projects, the resolver uses:

```text
cargo locate-project --workspace --message-format plain --manifest-path <manifest>
```

This delegates workspace resolution to Cargo rather than attempting to reproduce Cargo's manifest semantics in Lua.

The resolver:

1. Finds the nearest enclosing `Cargo.toml` or `rust-project.json`.
2. Uses the directory containing `rust-project.json` when that marker is the applicable project root.
3. Uses `cargo locate-project --workspace` to resolve the Cargo workspace manifest.
4. Normalizes the resulting path.
5. Falls back to the nearest Cargo manifest directory when Cargo cannot be used for the lookup.

The LSP root callback uses asynchronous process execution for Cargo root resolution. It verifies that the buffer remains valid and that its path has not changed before passing the resolved root to Neovim's LSP lifecycle.

The synchronous root helper is reserved for explicit workflows and tests. It is not the normal LSP startup path.

The resolver does not implement a general TOML parser. Cargo owns workspace interpretation, including workspace membership and exclusion rules.

### 6.3 Edition resolution and formatting

Conform owns Rust formatting through `rustfmt`.

The current formatter configuration supplies:

```lua
rustfmt = {
    options = {
        default_edition = "2024",
    },
},
```

The formatter uses the project edition when it can resolve it from the Cargo project configuration. Otherwise, it uses the configured fallback edition.

Edition validation covers:

- Explicit package edition handling.
- Workspace-inherited edition handling.
- The configured fallback when no project edition is available.
- The final rustfmt argument list.

The workspace-inherited edition validation passed. The earlier exploratory assertion that expected the fallback edition for the workspace fixture was incorrect; the observed formatter arguments contained the expected workspace edition.

Cargo remains the authority for package and workspace edition semantics. Do not introduce a custom TOML parser solely to reproduce that behavior.

The formatter preserves Conform's stdin/stdout behavior. It must not independently rewrite the source file.

Existing formatting policies remain unchanged:

- `:Format` remains the manual formatting entry point.
- `<leader>cf` remains governed by centralized keymaps.
- Format-on-save remains disabled by default.
- LSP formatting fallback remains disabled by default.

### 6.4 rust-analyzer configuration

Configure and enable rust-analyzer through Neovim's native LSP API:

```lua
vim.lsp.config("rust_analyzer", {
    -- Rust-specific settings and callbacks.
})

vim.lsp.enable("rust_analyzer")
```

`nvim-lspconfig` supplies the server definition. Neovim's native API remains responsible for configuring and enabling it.

Do not use the legacy `require("lspconfig").rust_analyzer.setup(...)` interface.

The current configuration:

- Uses the Rust root resolver.
- Enables Cargo build-script support.
- Enables procedural macro support.
- Keeps `cargo.allFeatures` disabled.
- Uses `check.command = "check"` by default.
- Uses `check.command = "clippy"` when the optional Clippy setting is enabled and the executable is available.
- Preserves shared LSP attachment behavior.

The effective settings include:

```lua
cargo = {
    allFeatures = false,
    buildScripts = {
        enable = true,
    },
},
procMacro = {
    enable = true,
},
check = {
    command = check_command,
},
```

Do not enable `cargo.targetDir = true` by default. A separate target directory duplicates build artifacts and consumes additional disk space. Consider it only after reproducing a real build-contention problem.

### 6.5 Rust-specific LSP attachment behavior

The Rust module uses a dedicated `LspAttach` autocmd group.

When `rust-analyzer` attaches, it disables:

- `documentFormattingProvider`
- `documentRangeFormattingProvider`

This keeps Conform as the only Rust formatting authority.

The Rust-specific callback must not replace the shared LSP attachment callback or duplicate shared keymaps and diagnostics.

### 6.6 Rust buffer settings

Neovim's built-in `.rs` filetype detection is used. No additional filetype detector is required.

The existing autocmd configuration applies these Rust buffer-local defaults:

```lua
vim.opt_local.shiftwidth = 4
vim.opt_local.tabstop = 4
vim.opt_local.softtabstop = 4
vim.opt_local.expandtab = true

vim.opt_local.foldmethod = "expr"
vim.opt_local.foldexpr = "v:lua.vim.treesitter.foldexpr()"
```

These are editor defaults. `rustfmt` owns formatted output.

The same Rust `FileType` callback registers the Rust-specific buffer-local keymaps:

```lua
require("config.keymaps").rust(event.buf)
```

Do not add a custom `commentstring` unless native commenting is demonstrated to be incorrect for Rust.

### 6.7 Native Cargo command

The project implements an optional native `:Cargo` command in `lua/config/rust.lua`.

It is registered only when the Rust language pack is enabled.

Examples:

```vim
:Cargo build
:Cargo check
:Cargo test
:Cargo run -- --verbose
:Cargo clippy --all-targets
:Cargo fmt
```

The implementation:

- Resolves the Cargo project root.
- Checks that Cargo is executable.
- Passes arguments as a list rather than a shell-concatenated string.
- Opens a dedicated terminal split.
- Sets the terminal working directory to the resolved project root.
- Preserves terminal output after the process exits.
- Reports failures to start the terminal job.

The helper is a convenience wrapper, not a replacement for Cargo.

Completed terminal buffers are intentionally preserved so that command output remains available. The Cargo helper's process lifecycle and exit-status requirements were reviewed as part of the completed design work. Do not claim that a generalized terminal lifecycle or additional exit-status UI is implemented unless it is added separately.

Do not add macro expansion, Cargo manifest navigation, or external documentation commands to the initial core implementation. These depend on rust-analyzer extension methods rather than standard LSP requests.

### 6.8 Centralized keymaps

All Rust keymaps are defined in `lua/config/keymaps.lua`, through the Rust-specific `M.rust(bufnr)` function.

They are registered as **buffer-local normal-mode mappings** when the Rust `FileType` autocmd runs. They are not global mappings and do not appear in non-Rust buffers.

| Mode | Key | Command | Description |
|---|---|---|---|
| Normal | `<leader>cr` | `:Cargo run` | Rust: Run project |
| Normal | `<leader>cb` | `:Cargo build` | Rust: Build project |
| Normal | `<leader>ct` | `:Cargo test` | Rust: Run tests |
| Normal | `<leader>cc` | `:Cargo check` | Rust: Check project |

The mappings dispatch to the native `:Cargo` command. They do not execute Cargo directly or duplicate its root-resolution and terminal logic.

The mappings use available entries in the existing `<leader>c` namespace:

- `<leader>cd` remains the diagnostics workflow.
- `<leader>cq` remains the diagnostics quickfix workflow.
- `<leader>cf` remains the manual formatting workflow.
- `<leader>ca` remains the code-action workflow.
- `<leader>ck` remains the signature-help workflow.

The Rust mappings do not override these existing shared mappings.

Do not define Rust keymaps inside `lua/langs/rust.lua` or `lua/config/rust.lua`.

## 7. Optional features

| Feature | Default | Current status |
|---|---:|---|
| Clippy diagnostics | Disabled | Implemented as an opt-in rust-analyzer check command |
| Native inlay hints | Disabled | Deferred; not implemented |
| Format-on-save | Disabled | Governed by global formatting policy |
| LSP formatting fallback | Disabled | Conform remains authoritative |
| All Cargo features | Disabled | Configured off |
| Separate rust-analyzer target directory | Disabled | Deferred |

### 7.1 Clippy

Clippy is optional and controlled by:

```lua
tools = {
    rust_clippy = false,
}
```

When enabled and available, rust-analyzer uses:

```lua
check = {
    command = "clippy",
}
```

Otherwise, the normal check command remains:

```lua
check = {
    command = "check",
}
```

The implementation checks executable availability before enabling Clippy. It must not repeatedly launch a missing command.

Do not introduce `nvim-lint`. Clippy diagnostics are collected through rust-analyzer's check mechanism.

### 7.2 Native inlay hints

Native inlay hints are deferred.

Do not document them as an implemented feature or add a configuration option until the implementation and its lifecycle have been designed.

### 7.3 Formatting policy

Conform owns Rust formatting. Rust-analyzer formatting capabilities remain disabled.

Do not add an automatic LSP formatting fallback for Rust.

## 8. Tree-sitter

The Rust pack declares the `rust` parser through the existing language registry.

The existing Tree-sitter integration discovers parser metadata from enabled language packs and installs missing parsers when the corresponding filetype is opened.

Rust support must not introduce a separate parser installation mechanism or require manual parser installation as the normal workflow.

Rust Tree-sitter support provides:

- Syntax highlighting.
- Syntax-aware folding.
- Structural syntax information used by existing native workflows.

The `toml` parser remains owned by the existing data-language pack.

## 9. Automated tests

Rust tests use the repository's existing validation conventions and focused scripts. They must not introduce a parallel plugin or test framework.

### 9.1 Root-resolution tests

`scripts/test-rust-roots.lua` validates root resolution using temporary project fixtures.

The verified cases include:

| Fixture | Expected result | Status |
|---|---|---|
| Standalone crate | Its own crate directory | Passed |
| Workspace member | Owning workspace directory | Passed |
| Excluded package | Appropriate package root | Passed |
| Nested workspace | Nearest applicable workspace | Passed |
| Workspace edition inheritance fixture | Cargo workspace resolution | Passed |
| `rust-project.json` project | Directory containing the project marker | Passed |

Temporary directories are cleaned up through the test cleanup pattern.

### 9.2 Edition tests

`scripts/test-rust-edition.lua` verifies:

- Explicit project edition arguments.
- Workspace-inherited edition arguments.
- The configured fallback edition.
- The final rustfmt argument list.

All edition validation scenarios passed. The workspace fixture produced the expected inherited edition argument. The earlier expectation of a fallback argument for that fixture was corrected.

### 9.3 LSP tests

`scripts/test-rust-lsp.lua` verifies:

- rust-analyzer attaches to a temporary Cargo project.
- The resolved LSP root matches the expected project root.
- Document formatting is disabled.
- Range formatting is disabled.

The test asserts the root directory rather than merely printing it.

The formatting assertions inspect the attached client's effective capabilities after the Rust attachment behavior has run.

### 9.4 Clippy tests

`scripts/test-rust-clippy.lua` verifies:

- Clippy is disabled by default.
- Enabling the option selects the `clippy` check command when available.
- Disabling the option restores the normal `check` command.

### 9.5 Tree-sitter tests

`scripts/test-rust-parser.lua` verifies that:

- The enabled Rust pack contributes the parser mapping.
- The existing Tree-sitter lifecycle installs the missing Rust parser.
- The parser can be loaded.
- Rust source can be parsed.
- Highlighting can be activated.

These tests exercise the existing automatic installation lifecycle rather than manually installing the parser.

### 9.6 Configuration, buffer, and keymap tests

Validation covers:

- The Rust pack is enabled through the existing language configuration.
- The registry uses its actual metadata schema.
- The native LSP configuration is registered.
- The Rust filetype is recognized.
- Conform registers `rustfmt`.
- Rust buffer-local options are applied.
- The `:Cargo` command is registered only when Rust support is enabled.
- Shared LSP keymaps continue to attach.
- All four Rust Cargo mappings are registered in Rust buffers.
- The mappings are buffer-local and isolated from non-Rust buffers.
- Each mapping has the expected command and description.

The verified mappings are:

| Key | Expected right-hand side | Verified description |
|---|---|---|
| `<leader>cr` | `<cmd>Cargo run<CR>` | `Rust: Run project` |
| `<leader>cb` | `<cmd>Cargo build<CR>` | `Rust: Build project` |
| `<leader>ct` | `<cmd>Cargo test<CR>` | `Rust: Run tests` |
| `<leader>cc` | `<cmd>Cargo check<CR>` | `Rust: Check project` |

Offline tests do not require a running Rust toolchain or network access unless the test is explicitly an integration test.

## 10. Integration validation

Integration validation was completed with the external Rust toolchain available to the Neovim process.

On Windows, compiler and linker discovery was investigated as part of the toolchain review. The separate installation guide owns the system prerequisites and records the remaining shell-discovery limitation.

### 10.1 Validate LSP attachment and root resolution

Validation covered standalone crates and workspace projects.

The checks confirmed:

- `rust-analyzer` starts successfully.
- The client attaches to the buffer.
- The resolved root matches the Cargo project root.
- Document and range formatting capabilities are disabled.
- Workspace member files resolve to the expected workspace root.

### 10.2 Validate diagnostics and language intelligence

Rust-analyzer diagnostics and the existing shared LSP workflows were included in integration validation.

The implementation retains the shared workflows for hover, definition navigation, references, rename, code actions, and diagnostics.

### 10.3 Validate formatting

Formatting validation used:

```vim
:ConformInfo
:Format
```

The checks confirmed:

- Conform selects `rustfmt`.
- The formatter receives the expected edition argument.
- Explicit and workspace-inherited edition handling works for the tested fixtures.
- The configured fallback edition is used when no project edition is available.
- The formatter preserves stdin/stdout behavior.
- The output is correctly formatted.
- Rust-analyzer formatting is not invoked.

### 10.4 Validate Cargo execution

Cargo validation covered:

```vim
:Cargo check
:Cargo test
:Cargo run
```

The checks confirmed:

- The terminal opens.
- Cargo runs from the resolved project root.
- Arguments are forwarded correctly.
- Output remains visible.
- The terminal remains usable while the process runs.
- Completed output remains available.
- Missing-project handling reports the absence of a Cargo project.

The four Rust buffer-local mappings were also verified to dispatch to the corresponding native `:Cargo` commands.

### 10.5 Validate optional Clippy

Clippy validation confirmed that:

- The optional setting controls Clippy integration.
- The Clippy check command is selected when enabled and available.
- Disabling the option restores the normal `check` command.

### 10.6 Windows environment validation

Windows toolchain validation covered discovery and availability of:

- `rust-analyzer`
- `rustfmt`
- `cargo`
- `rustc`
- MSVC compiler and linker files
- Windows SDK headers and libraries

The Rust executables were available to the tested PowerShell environment. The MSVC compiler and linker files were found on disk.

However, `cl.exe` and `link.exe` were not discoverable through the current PowerShell `PATH`, including after the Visual Studio developer-shell initialization script displayed its startup banner. The Visual C++ workload was also not confirmed by the `vswhere` workload query.

A clean Cargo test project built, tested, and ran successfully. This confirms the tested Cargo workflow but does not establish direct MSVC executable discovery for every native dependency or build script.

Do not hardcode Visual Studio installation paths in the Rust language pack. Environment initialization belongs to operating-system and toolchain setup.

## 11. Validation and acceptance status

### 11.1 Verified implementation behavior

The following implementation and integration checks passed:

| Area | Validation | Result |
|---|---|---|
| Rust metadata | Language registry integration | Passed |
| Cargo roots | Standalone and workspace fixtures | Passed |
| Project markers | `rust-project.json` resolution | Passed |
| LSP | rust-analyzer attachment and root assertion | Passed |
| LSP formatting | Document and range formatting disabled | Passed |
| LSP settings | Cargo build scripts and procedural macros enabled; all features disabled | Passed |
| Clippy | Optional check-command selection | Passed |
| Rust formatter | Conform formatter resolution and 2024 fallback | Passed |
| Edition handling | Explicit, workspace-inherited, and fallback edition arguments | Passed |
| Buffer settings | Rust indentation and folding options | Passed |
| Rust keymaps | Four buffer-local mappings and command targets | Passed |
| Keymap isolation | Rust mappings absent from non-Rust buffers | Passed |
| Tree-sitter | Automatic parser installation and parsing | Passed |
| Cargo helper | Root resolution, command execution, and terminal output | Passed |
| Windows toolchain | Rust executables, MSVC files, and Windows SDK discovery reviewed | Passed |
| Static validation | StyLua, syntax check, and whitespace validation | Passed |
| Documentation | Implementation and architecture review | Passed |

The Windows toolchain result records successful discovery of the required files and tools. It does not mean that direct `cl.exe` and `link.exe` discovery through the current PowerShell `PATH` has been resolved.

### 11.2 Repository validation

The repository validation commands completed successfully:

```powershell
stylua --check .
nvim --headless -u NONE -l .\scripts\check-syntax.lua
git diff --check
```

Tests that depend on the actual repository configuration were run with the repository's `init.lua`.

### 11.3 Validation and acceptance status

All Rust implementation tests, integration checks, design reviews, and documentation reviews have been completed successfully.

- [x] Validate explicit and workspace-inherited Rust edition handling.
- [x] Verify Cargo process exit-status reporting requirements.
- [x] Complete the Windows toolchain discovery review.
- [x] Review the final documentation against the implementation.
- [x] Complete the Stage 13 acceptance review.

**Status:** Rust support validation is complete. Stage 13 Rust support is accepted.

No further Rust tests or validation runs are required for this accepted implementation unless the scope or implementation changes.

The remaining MSVC shell-discovery limitation belongs to the external Windows toolchain environment. It does not reopen the accepted Neovim Rust integration.

## 12. Troubleshooting

| Symptom | Possible cause | Investigation |
|---|---|---|
| rust-analyzer does not attach | Missing executable, invalid root, or server configuration issue | Check executable availability, `:checkhealth vim.lsp`, and the resolved root |
| Standard-library navigation is incomplete | Rust source component unavailable | Check `rust-src` availability |
| Rust formatting fails | Missing rustfmt or invalid Conform arguments | Inspect `:ConformInfo` and formatter arguments |
| Edition-specific syntax fails during formatting | Incorrect edition detection or fallback | Inspect the package manifest and formatter arguments |
| Workspace member uses the wrong root | Cargo root resolution issue | Compare the resolved root for each member |
| Workspace member uses the wrong edition | Edition configuration or detection issue | Inspect `edition.workspace = true` and `[workspace.package]` |
| Clippy diagnostics do not appear | Clippy unavailable, disabled, or server not reconfigured | Check the optional component and effective rust-analyzer setting |
| Formatting uses the LSP | Rust formatting capabilities remain enabled | Inspect the attached client's formatting capabilities |
| Cargo command cannot find a project | Current buffer is outside a Cargo project | Inspect the Rust root resolver result |
| Cargo command uses the wrong directory | Root resolution is incorrect | Check the root helper against the workspace fixture |
| Cargo build cannot find the linker on Windows | MSVC environment is unavailable to the build process | Follow the Windows installation guide and check the shell environment |

Useful Neovim diagnostics:

```vim
:checkhealth vim.lsp
:ConformInfo
:messages
```

External tool versions:

```powershell
rust-analyzer --version
rustfmt --version
cargo --version
rustc --version
```

Check Clippy only when it is enabled:

```powershell
cargo clippy --version
```

For rust-analyzer logging, set `RA_LOG` before starting Neovim using the syntax appropriate to the current shell. Keep verbose logging disabled by default.

## 13. Architecture decisions

| Decision | Policy |
|---|---|
| Language server | rust-analyzer |
| LSP configuration | Native Neovim LSP API |
| Server definitions | Existing nvim-lspconfig |
| Formatter | rustfmt through Conform |
| Formatting authority | Conform only |
| Formatting trigger | Manual by default |
| Linter | Clippy through rust-analyzer, optional |
| Linting plugin | No nvim-lint |
| Workspace handling | Cargo workspace root resolution |
| Edition handling | Explicit, workspace-inherited, and fallback edition handling validated |
| Cargo execution | Native terminal workflow through `:Cargo` |
| Cargo keymaps | Centralized, Rust-buffer-local mappings |
| Inlay hints | Deferred |
| Parser | Existing Tree-sitter infrastructure |
| TOML ownership | Existing data-language pack |
| Debugging | Deferred to Stage 14 |
| New plugins | None |
| Tool installation | Separate installation guide; never during startup |

### Deferred functionality

The following remain outside the accepted Stage 13 Rust core-pack implementation:

- CodeLLDB and DAP configuration.
- Native inlay-hint configuration.
- Advanced Cargo workspace management.
- Rust-specific UI plugins.
- Automatic Rust toolchain installation.
- Experimental rust-analyzer extension commands.
- Full TOML parsing inside Rust helpers.
- Automatic format-on-save unless separately approved through the global formatting policy.

Debugging belongs to Stage 14. Do not pull it into Stage 13.

## 14. References

Official documentation:

- [rust-analyzer – Installation](https://rust-analyzer.github.io/book/installation.html)
- [rust-analyzer – Configuration](https://rust-analyzer.github.io/book/configuration.html)
- [Cargo Book](https://doc.rust-lang.org/cargo/)
- [Cargo manifest reference](https://doc.rust-lang.org/cargo/reference/manifest.html)
- [Rust editions](https://doc.rust-lang.org/edition-guide/)
- [rustfmt](https://github.com/rust-lang/rustfmt)
- [Clippy](https://doc.rust-lang.org/clippy/)
- [Neovim LSP documentation](https://neovim.io/doc/user/lsp.html)
- [Conform.nvim](https://github.com/stevearc/conform.nvim)
- [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig)

---

**Document ownership:** Stage 13 – Language Packs
**Core pack:** Rust
**Document:** `docs/architecture/rust-support.md`
**Acceptance:** Complete
**Implementation principle:** Minimum installation. Compose the rest.
