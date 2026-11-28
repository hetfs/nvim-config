# Debugging (DAP)

## Status

**In progress**

Plugin selection is finalized. The core DAP implementation has started, and the initial LLDB adapter registration and C test compilation have been validated.

The end-to-end C debugging workflow remains in progress. UI integration, language configurations, external dependency setup, automated validation, and cross-platform testing remain outstanding.

Plugin selection is final. Remaining work concerns implementation, dependency setup, compatibility, and validation—not further plugin evaluation.

## 1. Objective

Establish a modular, native-first debugging environment for Neovim using the Debug Adapter Protocol (DAP).

The integration must provide:

- Breakpoint management.
- Debug session lifecycle management.
- Stepping through code.
- Variable, scope, and expression inspection.
- Debug console and REPL access.
- Language-specific debugging.
- Cross-platform support for Windows, Linux, and macOS.
- Explicit external dependency management.
- Automated smoke validation and documented interactive tests.

**Minimum supported Neovim:** 0.12
**Documentation target:** 0.13

## 2. Architecture and boundaries

The debugging integration must remain independent of the LSP configuration.

It must follow the existing native-first configuration architecture and reuse the established separation between plugin declarations, configuration modules, and centralized keymaps.

### Component responsibilities

| Component | Responsibility |
|---|---|
| `nvim-dap` | Core DAP client and debugging sessions |
| `nvim-dap-ui` | Debugging interface |
| `nvim-nio` | Required asynchronous dependency for DAP UI |
| `nvim-dap-virtual-text` | Inline variable and expression information |
| `lua/config/dap/adapters.lua` | External debugger adapter definitions |
| `lua/config/dap/setup.lua` | DAP initialization and adapter registration |
| Language configuration modules | Language-specific launch configurations |
| External dependencies | Debugger executables, runtimes, and adapter packages |
| Smoke tests | Configuration and integration validation |

The integration must not introduce another plugin manager or silently install external dependencies.

All user-facing keymaps remain centralized in:

```text
lua/config/keymaps.lua
```

### Architectural principles

- Keep plugin declarations separate from DAP configuration.
- Keep adapter definitions separate from language launch configurations.
- Keep adapter registration centralized.
- Avoid duplicate adapter registration.
- Do not introduce an additional plugin-management framework.
- Do not introduce unnecessary abstraction layers.
- Keep debugger executables and runtimes independent of Neovim plugin installation.
- Implement language-specific modules incrementally, based on validated debugging workflows.

## 3. Final plugin selection

Plugin selection is finalized. No plugin is awaiting evaluation.

| Plugin | Repository | Decision |
|---|---|---|
| `nvim-dap` | [mfussenegger/nvim-dap](https://github.com/mfussenegger/nvim-dap) | Approved |
| `nvim-dap-ui` | [rcarriga/nvim-dap-ui](https://github.com/rcarriga/nvim-dap-ui) | Approved |
| `nvim-nio` | [nvim-neotest/nvim-nio](https://github.com/nvim-neotest/nvim-nio) | Approved dependency |
| `nvim-dap-virtual-text` | [theHamsta/nvim-dap-virtual-text](https://github.com/theHamsta/nvim-dap-virtual-text) | Approved |
| OSV | [jbyuki/one-small-step-for-vimkind](https://github.com/jbyuki/one-small-step-for-vimkind) | Approved |

The implementation must use the existing `vim.pack` architecture.

The plugin inventory and dependency declarations must reflect these decisions. Do not introduce another plugin-selection phase.

Approval does not mean that a plugin has already been declared, installed, configured, or validated.

## 4. Language debugger selection

The debugger choices are finalized.

| Language | Debugger or adapter | Scope |
|---|---|---|
| C/C++ | LLVM LLDB DAP (`lldb-dap`) | Native debugging |
| Rust | LLVM LLDB DAP (`lldb-dap`) | Native debugging |
| Python | debugpy | Python debugging |
| JavaScript/TypeScript | vscode-js-debug | JavaScript and TypeScript debugging |
| PowerShell | PowerShell Editor Services | PowerShell debugging |
| Go | Delve | Optional language integration |
| Lua | EmmyLua DAP | Standalone Lua debugging |
| Neovim Lua | OSV | Lua running inside Neovim |
| Bash | Bash Debug | Bash debugging |

C, C++, and Rust share the LLVM LLDB DAP adapter definition. Their launch configurations remain language-specific.

The selected debugger integrations must be implemented and validated. Compatibility differences between operating systems must be handled in the relevant adapter or platform-specific configuration.

The language selection is final, but implementation must follow the validation sequence in Section 12.

## 5. Lua debugging

### 5.1 Standalone Lua — EmmyLua DAP

Repository: [EmmyLua DAP](https://github.com/EmmyLuaLs/emmylua_dap)

EmmyLua DAP provides a standalone Lua debugging adapter. It uses an executable and a native `emmy_core` module.

The implementation must account for:

- The `emmylua_dap` executable.
- The matching `emmy_core` native module.
- Native module extensions: `.dll`, `.so`, and `.dylib`.
- Operating-system and CPU architecture compatibility.
- Lua ABI compatibility.
- LuaJIT compatibility.
- Explicit executable and module paths.
- A real DAP launch and debugging session.

The upstream project documents LuaJIT support, and its underlying debugger core provides build options for Lua 5.1 through 5.5 and LuaJIT. These build options do not guarantee that every prebuilt executable and native module combination is available or compatible.

Therjkefore, validate the exact release artifacts and runtime combination before declaring the integration functional.

The application being debugged must load `emmy_core` and initialize its debugging connection. The documented API includes `tcpListen`, with optional `waitIDE` and `breakHere` calls.

Do not download or install debugger artifacts automatically during Neovim startup.

Record the selected release, artifact filename, platform, architecture, checksum, installation path, and supported Lua runtime.

### 5.2 Neovim Lua runtime — OSV

Repository: [one-small-step-for-vimkind](https://github.com/jbyuki/one-small-step-for-vimkind)

OSV is used to debug Lua code running inside Neovim itself.

Supported debugging targets include:

- Neovim configuration files.
- Lua plugins.
- Lua scripts executed inside Neovim.
- Neovim runtime behavior.

OSV uses a two-instance workflow:

1. Start the target Neovim instance.
2. Launch the OSV debugging server in that instance.
3. Open a second Neovim instance as the debugging client.
4. Set breakpoints in the client.
5. Attach to the target instance.
6. Execute the target Lua code and inspect the debugging session.

The documented server API includes:

```lua
require("osv").launch({
  port = 8086,
})
```

The DAP adapter uses the `nlua` type and an attach request. The default server endpoint is `127.0.0.1:8086`.

The implementation must document:

- Server startup and shutdown.
- Client attachment.
- Port configuration.
- Source path matching.
- Breakpoint behavior.
- Output capture limitations.
- Exception handling.
- The two-instance workflow.

OSV is a separate integration from standalone Lua debugging. Do not combine its configuration with EmmyLua DAP.

## 6. Bash debugging

### 6.1 Bash Debug adapter

Repository: [vscode-bash-debug](https://github.com/rogalmic/vscode-bash-debug)

Bash Debug provides a DAP frontend for BashDB. The VS Code extension package includes BashDB.

The adapter package must be acquired explicitly and pinned to a known version. The implementation must not download or extract the extension automatically during Neovim startup.

Proposed installation location:

```lua
vim.fn.stdpath("data") .. "/dap/bash-debug-adapter"
```

Allow an explicit override through:

```text
NVIM_DAP_BASH_DEBUG
```

Resolve the adapter entrypoint from the unpacked extension package.

The documented adapter contract includes:

| Property | Purpose |
|---|---|
| `type` | `bashdb` |
| `program` | Adapter entrypoint, `out/bashDebug.js` |
| `runtime` | Node.js |
| `pathBash` | Bash executable |
| `pathBashdb` | BashDB executable |
| `pathBashdbLib` | BashDB library path |
| `pathCat` | `cat` executable |
| `pathMkfifo` | `mkfifo` executable |
| `pathPkill` | `pkill` executable |
| `terminalKind` | Debug terminal mode |
| `trace` | Adapter tracing |
| `env` | Environment variables |

The launch configuration must provide the target `program`.

Do not add undocumented properties such as `useWSL`.

The upstream package manifest declares version `0.3.9` and a Node.js engine range of `^12.18.3`. This is an older adapter. Validate its operation with the selected Node.js runtime rather than assuming compatibility.

### 6.2 Bash requirements

The upstream debugger requires Bash 4.0 or later. The upstream documentation identifies Bash 4.0–4.2 as untested.

This project adopts Bash 4.3 or later as its minimum supported version.

Required utilities include:

- `cat`
- `mkfifo`
- `rm`
- `pkill`

Verify their availability and executable paths before starting a debugging session.

### 6.3 Linux

Use the native Bash installation.

Resolve the required utilities from the host environment and validate the Bash version.

### 6.4 macOS

Do not rely on the system `/bin/bash`, which may be too old.

Install and use Homebrew Bash.

Resolve Bash in this order:

1. Explicit configuration override.
2. `/opt/homebrew/bin/bash`.
3. `/usr/local/bin/bash`.
4. `bash` available on `PATH`.

Verify the resolved executable and version.

Use `/usr/bin/pkill` where applicable. Do not assume `/usr/local/bin/pkill` is valid.

### 6.5 Windows and WSL

Use WSL for Bash execution.

The Node.js runtime runs on the Windows host. Bash, BashDB, and the required Unix utilities run inside WSL.

`pathBash` must point to Bash inside the WSL environment. It must not point to `wsl.exe` or a Windows Bash executable.

Validate:

- Windows-to-WSL path conversion.
- Drive-letter paths.
- Paths containing spaces.
- WSL UNC paths.
- Source file and breakpoint mapping.
- Debugger process termination.
- Cleanup of named pipes and child processes.

Prefer `wsl.exe -e wslpath -a <path>` for path conversion when needed. Use argument arrays and preserve paths containing spaces. Avoid fragile string concatenation or drive-letter-only conversion helpers.

Implement a dedicated path-mapping helper only when the adapter's own path handling is insufficient.

### 6.6 Bash Debug limitations

Document and test the known upstream limitations:

- The debugger may stop at the first command.
- `$0` path behavior can differ from expectations.
- `BASH_REMATCH` may be overwritten.
- Interactive scripts require an appropriate terminal mode.
- Windows path handling requires special attention.

A successful adapter startup alone does not establish a working Bash debugging integration.

## 7. Current and target file structure

### 7.1 Existing implementation

The current repository already has the following DAP structure:

```text
lua/
├── config/
│   ├── dap/
│   │   ├── adapters.lua
│   │   └── setup.lua
│   │
│   └── keymaps.lua
│
└── plugins/
    └── dap.lua
```

Responsibilities:

| File | Responsibility |
|---|---|
| `lua/plugins/dap.lua` | Declares the `nvim-dap` plugin through `vim.pack` |
| `lua/config/dap/adapters.lua` | Defines external debugger adapter specifications |
| `lua/config/dap/setup.lua` | Initializes DAP and registers adapters |
| `lua/config/keymaps.lua` | Defines all user-facing debugging keymaps |
| `init.lua` | Controls configuration and module loading |

Keep this structure as the foundation of Stage 14.

Do not move the existing DAP modules into a new `lua/plugins/dap/` hierarchy.

### 7.2 Incremental target structure

Language configuration modules must be introduced only after the C debugging workflow has been validated.

The initial structure remains:

```text
lua/
├── config/
│   ├── dap/
│   │   ├── adapters.lua
│   │   └── setup.lua
│   │
│   └── keymaps.lua
│
└── plugins/
    └── dap.lua
```

After successful C validation, extend the existing configuration directory:

```text
lua/
├── config/
│   ├── dap/
│   │   ├── adapters.lua
│   │   ├── setup.lua
│   │   └── languages/
│   │       ├── c_cpp.lua
│   │       ├── rust.lua
│   │       ├── python.lua
│   │       ├── javascript.lua
│   │       ├── powershell.lua
│   │       ├── go.lua
│   │       ├── lua.lua
│   │       └── shell.lua
│   │
│   └── keymaps.lua
│
└── plugins/
    └── dap.lua
```

This is a future target, not the current repository state.

Create only the modules required by the implementation phase being validated. Do not create empty files or placeholder directories for integrations that have not started.

### 7.3 File responsibilities

| File | Responsibility |
|---|---|
| `plugins/dap.lua` | Plugin declarations |
| `config/dap/adapters.lua` | Adapter definitions |
| `config/dap/setup.lua` | Core DAP initialization and adapter registration |
| `config/dap/languages/c_cpp.lua` | C/C++ configurations |
| `config/dap/languages/rust.lua` | Rust configurations |
| `config/dap/languages/python.lua` | Python configurations |
| `config/dap/languages/javascript.lua` | JavaScript/TypeScript configurations |
| `config/dap/languages/powershell.lua` | PowerShell configurations |
| `config/dap/languages/go.lua` | Go configurations |
| `config/dap/languages/lua.lua` | EmmyLua and OSV configurations |
| `config/dap/languages/shell.lua` | Bash configurations |
| `config/keymaps.lua` | All user-facing debugging keymaps |

Keep adapter definitions separate from language launch configurations. Avoid duplicate adapter registration and unnecessary abstraction layers.

The language modules must not become responsible for installing external dependencies.

## 8. Debugging UI

Use `nvim-dap-ui` for the debugging interface and `nvim-dap-virtual-text` for inline variable information.

Use `nvim-nio` as the required asynchronous dependency of `nvim-dap-ui`.

The UI must:

- Open when a debugging session starts.
- Close when a debugging session terminates.
- Avoid duplicate UI windows.
- Preserve normal editor workflows.
- Handle failed session startup safely.
- Avoid interfering with existing window and terminal management.

UI integration must follow successful validation of the core C debugging workflow. Plugin approval does not require introducing UI complexity before the core debugger is proven functional.

## 9. Keymap contract

All keymaps must be defined in:

```text
lua/config/keymaps.lua
```

Use `<leader>d` as the debugging namespace.

| Keymap | Description |
|---|---|
| `<leader>db` | Debug: Toggle breakpoint |
| `<leader>dB` | Debug: Set conditional breakpoint |
| `<leader>dc` | Debug: Continue |
| `<leader>di` | Debug: Step into |
| `<leader>do` | Debug: Step over |
| `<leader>du` | Debug: Step out |
| `<leader>dr` | Debug: Run last configuration |
| `<leader>ds` | Debug: Start or attach |
| `<leader>dt` | Debug: Terminate |
| `<leader>de` | Debug: Evaluate expression |
| `<leader>dw` | Debug: Toggle UI |

Register the which-key group as:

```lua
{ "<leader>d", group = "+debug" }
```

Before finalizing the mappings, check for collisions with:

- Existing `<leader>t` terminal and Neotest mappings.
- Buffer-local `<leader>c` mappings.
- Existing global mappings.
- Other plugin integrations.

Use descriptive mapping metadata with the `Debug: ` prefix.

The existing validated mappings must be preserved unless a deliberate, documented change is required.

## 10. External dependency management

External debugger executables and runtimes must be managed separately from plugin installation.

Requirements:

- No silent downloads.
- No automatic debugger installation during startup.
- Explicit installation instructions.
- Version and platform documentation.
- Executable discovery and validation.
- Clear diagnostics for missing dependencies.
- Environment-variable overrides where appropriate.
- No hard-coded user-specific paths.
- No assumptions that a debugger installed on one platform exists on another.

The Bash Debug VSIX and EmmyLua artifacts must have explicit acquisition and installation instructions.

Debugger paths must be configurable without modifying the core DAP architecture.

For C, C++, and Rust, use the shared LLVM `lldb-dap` adapter definition. Validate the selected executable and compiler/debug-symbol compatibility on each supported platform.

## 11. Validation strategy

### 11.1 Static validation

Run:

```powershell
nvim -l scripts/check-syntax.lua
stylua --check .
```

### 11.2 General smoke validation

Run:

```powershell
$env:NVIM_APPNAME = "nvim-config"
nvim --headless "+luafile scripts/smoke.lua"
```

### 11.3 Stage 14 smoke validation

Add:

```text
scripts/smoke/suites/stage14_dap.lua
```

The suite must validate:

- DAP module loading.
- Required plugin availability.
- Adapter registration.
- Language configuration loading, once language modules exist.
- Keymap registration.
- Dependency diagnostics.
- Configuration errors and missing modules.

Run the dedicated suite:

```powershell
$env:SMOKE_ONLY = "stage14_dap"
nvim --headless "+luafile scripts/smoke.lua"
Remove-Item Env:SMOKE_ONLY
```

The smoke suite validates configuration and integration structure. It does not replace real debugger sessions.

Do not make language configuration loading a required test until those modules have been introduced.

### 11.4 Interactive validation

For every supported debugger, verify:

1. Adapter startup.
2. Launch or attach.
3. Breakpoint creation and activation.
4. Step into, step over, and step out.
5. Variable and scope inspection.
6. Expression evaluation.
7. Continue and termination.
8. Process cleanup.
9. No orphaned debugger processes.

For Bash on Windows, also verify WSL path mapping and cleanup.

For OSV, verify the two-instance workflow.

For EmmyLua, verify the exact executable/native module/runtime combination.

### 11.5 C debugging acceptance test

C is the first end-to-end validation target.

Use a dedicated test program compiled with debug symbols and without optimization.

The C workflow must verify:

1. The active buffer is recognized as C.
2. The C launch configuration resolves the correct executable.
3. `lldb-dap` starts successfully.
4. The executable launches under the debugger.
5. A breakpoint at `main` is resolved and activated.
6. Execution stops at the expected source location.
7. Local variables can be inspected.
8. Step over, step into, and step out work where applicable.
9. Continue resumes execution.
10. The process terminates cleanly.

A successful executable build, adapter registration, or debugger launch alone does not establish successful end-to-end debugging.

Only after this workflow passes should permanent language-specific configuration modules be introduced.

### 11.6 Platform matrix

| Platform | Required validation |
|---|---|
| Windows | Native debugger integrations, WSL Bash integration, and path handling |
| Linux | Native debugger integrations and Bash |
| macOS | Native debugger integrations and Homebrew Bash |

Test each supported platform independently.

A platform that has not been tested must be recorded as **unverified**, not passed.

## 12. Implementation phases

Implementation must proceed incrementally. Validate the existing architecture and the C debugging workflow before expanding language configurations or adding UI integration.

### Phase 01 — Existing architecture and core DAP

- Preserve the existing DAP directory structure.
- Confirm plugin declaration and loading through `vim.pack`.
- Confirm DAP initialization order in `init.lua`.
- Validate `nvim-dap` loading.
- Preserve centralized debugging keymaps.
- Confirm LLDB executable discovery.
- Confirm LLDB adapter registration.
- Keep the adapter definition independent of language launch configurations.

**Exit criteria:** Core DAP loads without errors, the adapter is registered, and the existing configuration structure remains intact.

### Phase 02 — C debugging proof of functionality

- Create a dedicated C smoke-test program.
- Compile with debug symbols and without optimization.
- Configure a temporary C launch configuration.
- Launch the executable through `lldb-dap`.
- Verify a breakpoint at `main`.
- Verify variable inspection.
- Verify stepping and continuation.
- Verify clean process termination.
- Record any compiler, debug-symbol, or platform compatibility limitations.

**Exit criteria:** The complete C debugging acceptance test in Section 11.5 passes.

Do not introduce permanent language-specific configuration modules before this phase passes.

### Phase 03 — Adapter architecture and language configuration foundation

After C validation:

- Preserve `config/dap/adapters.lua` and `config/dap/setup.lua`.
- Introduce `config/dap/languages/` incrementally.
- Move the validated C configuration into its permanent language module.
- Add C++ and Rust configurations using the shared LLVM LLDB adapter.
- Add executable discovery and dependency diagnostics.
- Validate adapter registration and language configuration loading.
- Avoid duplicate adapter definitions.

**Exit criteria:** The shared adapter architecture works with the validated C workflow and the first additional native language integrations.

### Phase 04 — Remaining language integrations

- Implement Python with debugpy.
- Implement JavaScript and TypeScript with vscode-js-debug.
- Implement PowerShell with PowerShell Editor Services.
- Implement Go with Delve as an optional integration.
- Implement standalone Lua with EmmyLua DAP.
- Implement Neovim Lua debugging with OSV.
- Implement Bash Debug.

Each integration must have explicit dependencies, launch configurations, diagnostics, and interactive validation.

**Exit criteria:** Each implemented integration passes its applicable interactive tests. Unimplemented integrations remain explicitly outstanding.

### Phase 05 — External dependencies

- Document debugger installation.
- Pin external adapter versions.
- Add explicit path overrides.
- Validate executable discovery.
- Add platform-specific resolution.
- Verify native module compatibility.
- Document required runtimes and supporting utilities.

**Exit criteria:** External dependencies can be discovered and validated without automatic installation or user-specific hard-coded paths.

### Phase 06 — UI and workflow integration

- Configure `nvim-dap-ui`.
- Integrate `nvim-nio`.
- Configure `nvim-dap-virtual-text`.
- Validate UI startup and shutdown.
- Validate virtual text.
- Check keymap collisions.
- Verify terminal and window behavior.
- Confirm that DAP remains independent of LSP.

**Exit criteria:** UI lifecycle and editor workflow integration work without disrupting existing configuration behavior.

### Phase 07 — Platform validation

- Test Windows native debugger integrations.
- Test Windows and WSL Bash integration.
- Test Linux.
- Test macOS and Homebrew Bash.
- Verify debugger process cleanup.
- Record platform-specific limitations.

**Exit criteria:** Each tested platform has documented results. Untested platforms remain unverified.

### Phase 08 — Regression and closeout

- Run syntax validation.
- Run formatting checks.
- Run the complete smoke suite.
- Run the Stage 14 smoke suite.
- Complete interactive debugging tests.
- Update documentation and plugin inventory.
- Record verified platform coverage.

**Exit criteria:** All Stage 14 completion criteria are satisfied.

## 13. Completion criteria

Stage 14 must not be marked complete until:

- All approved plugins are integrated.
- The core DAP configuration loads without errors.
- Required adapters are registered correctly.
- Language configurations are implemented.
- External dependencies are documented and discoverable.
- Debug sessions can launch or attach successfully.
- Breakpoints, stepping, inspection, evaluation, and termination work.
- UI lifecycle behavior is correct.
- No keymap collisions remain.
- Windows, Linux, and macOS validation results are documented.
- Bash WSL path mapping and process cleanup are verified.
- EmmyLua executable and native module compatibility are verified.
- OSV two-instance debugging is verified.
- Static checks and smoke tests pass.

Do not mark an integration as complete based only on successful module loading.

Do not introduce permanent language configuration modules before the C debugging workflow passes its end-to-end acceptance test.

## 14. Closeout

**Stage:** 14 — Debugging (DAP)

**Closeout tag:** `14-debugging`

The stage remains **In progress** until all completion criteria are satisfied.

Plugin selection is final. The existing DAP architecture is retained. Implementation proceeds from core DAP and C debugging validation to language integrations, UI integration, external dependency management, and cross-platform verification.

No additional plugin evaluation or premature architectural restructuring is required.
