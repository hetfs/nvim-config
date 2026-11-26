# Debugging (DAP)

## Overview

This document defines the implementation architecture, integration requirements, dependencies, and validation strategy for Debug Adapter Protocol (DAP) support in `nvim-config`.

Stage 14 introduces debugging capabilities while preserving the project's native-first architecture, modular configuration, explicit dependency management, and stage-based acceptance process.

The implementation must integrate with the existing language-pack architecture without coupling debugging configuration to language-server configuration.

> **Implementation principle: Keep debugging modular, dependencies explicit, and debugger workflows independently verifiable.**

## Status

| Attribute | Value |
|---|---|
| Stage | 14 |
| Name | Debugging (DAP) |
| Status | Planned |
| Implementation | Not started |
| Primary integration | `nvim-dap` (candidate) |
| Optional interface | `nvim-dap-ui` (candidate) |
| Language coverage | Stage 13 languages and applicable runtimes |
| External dependencies | Debug adapters and debugger executables |
| Formal acceptance | Pending |

## Objectives

The primary objectives are:

- Introduce Debug Adapter Protocol support into Neovim.
- Establish a modular debugging architecture.
- Evaluate and select appropriate DAP plugins.
- Support applicable languages and runtimes from Stage 13.
- Keep debugger configurations independent of LSP configurations.
- Manage debugger executables separately from Neovim plugins.
- Provide consistent debugging keymaps and workflows.
- Support launch and attach configurations where applicable.
- Validate breakpoints, stepping, variable inspection, and debugger lifecycle operations.
- Preserve existing language-server, completion, formatting, and editing workflows.

## Architectural Principles

Stage 14 must follow the existing configuration architecture.

### Native-first integration

Prefer Neovim's built-in capabilities and established APIs wherever practical.

External plugins should provide functionality that cannot reasonably be implemented through existing native capabilities.

### Modular configuration

Keep debugging components independently maintainable.

Separate:

- DAP client configuration.
- Debugger adapter definitions.
- Language-specific launch configurations.
- Debugging interface configuration.
- Debugging keymaps.
- External debugger dependencies.

### Explicit dependency management

Neovim plugins must not silently install debugger executables or language runtimes.

Document external dependencies and provide explicit installation and verification procedures.

### Separation of responsibilities

DAP and LSP must remain separate integration layers.

| Component | Responsibility |
|---|---|
| Language packs | Language metadata and tooling requirements |
| LSP | Language intelligence, diagnostics, navigation, and code analysis |
| DAP | Debugger communication and execution control |
| Debug adapters | Communication between Neovim and language debuggers |
| Debug executables | Actual runtime debugging capabilities |
| Debug UI | Optional presentation of debugging information |

A language server must not become a prerequisite for debugging unless a specific integration explicitly requires it.

### Replaceability

Debugger adapters and UI integrations must remain replaceable without requiring a redesign of the entire debugging architecture.

Avoid unnecessary coupling between language-specific configurations and plugin implementations.

## Plugin Evaluation

### Candidate components

| Component | Intended responsibility | Admission status |
|---|---|---|
| `nvim-dap` | DAP client and debugging orchestration | Candidate |
| `nvim-dap-ui` | Debugging interface | Candidate |
| Debug adapters | Language-specific debugger communication | Selection pending |
| Debug executables | Runtime debugging capabilities | External dependencies |

### `nvim-dap`

Repository: https://github.com/mfussenegger/nvim-dap

`nvim-dap` is the primary candidate for implementing DAP functionality.

Its evaluation must cover:

- DAP session initialization.
- Adapter registration.
- Launch and attach configurations.
- Breakpoint management.
- Execution control.
- Variable and expression inspection.
- Stack and thread inspection.
- Session termination and cleanup.
- Compatibility with the minimum supported Neovim version.

Plugin admission must be based on architectural fit, maintenance, dependencies, compatibility, and actual debugging requirements.

### `nvim-dap-ui`

Repository: https://github.com/rcarriga/nvim-dap-ui

`nvim-dap-ui` is an optional candidate for presenting debugging information.

Its evaluation must determine whether it provides sufficient value over native Neovim windows and buffers.

Evaluate:

- Variable inspection.
- Call stacks.
- Breakpoints.
- Watches.
- REPL integration.
- Session lifecycle behavior.
- Window management.
- UI customization.
- Compatibility with the selected DAP client.

The plugin must not be admitted solely because it is commonly used alongside `nvim-dap`.

If native Neovim interfaces provide sufficient functionality, prefer the simpler implementation.

## Language and Debugger Coverage

Stage 14 evaluates debugging support against the established Stage 13 language baseline.

Debugger selection depends on actual runtime support, adapter availability, maintenance, and platform compatibility.

### Core language candidates

| Language | Candidate debugger | Classification |
|---|---|---|
| C | CodeLLDB or LLDB | Core |
| JavaScript/TypeScript | `vscode-js-debug` | Core |
| Lua | Lua debugger | Core |
| PowerShell | PowerShell Editor Services | Core |
| Python | `debugpy` | Core |
| Rust | CodeLLDB or LLDB | Core |
| Shell | Bash debugger | Core |

### Additional integration candidates

| Language / Integration | Candidate debugger | Classification |
|---|---|---|
| C++ | CodeLLDB or LLDB | Additional |
| Go | Delve | Additional |

### Languages and formats without an automatic DAP requirement

The following integrations do not automatically require dedicated debugger adapters:

- CSS
- Docker
- HTML
- JSON
- Markdown
- MDX
- SQL
- TOML
- YAML

Debugging support should only be introduced when an actual runtime or executable debugging requirement exists.

### Future language candidates

Java, Kotlin, Swift, and Zig remain outside the current Stage 14 language coverage.

Their debugging requirements may be evaluated independently if they are admitted into the supported language baseline.

### Debugger selection requirements

Every debugger integration must be evaluated against:

1. Runtime compatibility.
2. DAP adapter availability.
3. External executable requirements.
4. Windows, Linux, and macOS compatibility where applicable.
5. Installation and maintenance requirements.
6. Launch and attach capabilities.
7. Breakpoint and variable inspection support.
8. Documentation and verification requirements.

The candidate inventory is not an approved installation list.

## Proposed Configuration Architecture

The debugging integration should reuse the existing plugin and language-pack architecture.

The following is a proposed logical organization, not a claim about existing repository files.

```text
lua/
├── plugins/
│   └── dap.lua
│
└── dap/
    ├── init.lua
    ├── adapters.lua
    ├── configurations.lua
    ├── keymaps.lua
    ├── ui.lua
    └── languages/
        ├── c.lua
        ├── go.lua
        ├── javascript.lua
        ├── lua.lua
        ├── powershell.lua
        ├── python.lua
        ├── rust.lua
        └── shell.lua
```

### Module responsibilities

| Module | Responsibility |
|---|---|
| `plugins/dap.lua` | Plugin registration and loading |
| `dap/init.lua` | Shared DAP initialization and orchestration |
| `dap/adapters.lua` | Debug adapter registration |
| `dap/configurations.lua` | Shared debugger configuration handling |
| `dap/keymaps.lua` | Project-owned debugging mappings |
| `dap/ui.lua` | Optional debugging interface integration |
| `dap/languages/` | Language-specific debugger configurations |

The final directory structure must be evaluated against the existing configuration conventions before implementation.

Avoid creating unnecessary modules or abstraction layers.

### Configuration loading

The root configuration must retain explicit module loading.

The debugging implementation must not introduce a second plugin manager or an independent configuration framework.

Plugin installation, debugger registration, and language-specific activation must remain distinct operations.

## Debugger Adapter Management

Debugger adapters provide the communication layer between Neovim's DAP client and the underlying debugger.

Each adapter must have an explicit configuration.

### Adapter requirements

- Identify the adapter executable.
- Define executable arguments where required.
- Document runtime dependencies.
- Define supported launch and attach modes.
- Validate adapter initialization.
- Handle missing executables clearly.
- Avoid silent installation or downloads.
- Support platform-specific executable paths where necessary.

### External dependency separation

Debugger executables must be managed independently of Neovim plugins.

The implementation must not introduce Mason or automatic debugger installation.

Dependency documentation must identify:

- Debugger name.
- Supported language or runtime.
- Installation source.
- Platform requirements.
- Executable discovery requirements.
- Version or compatibility requirements where applicable.
- Verification procedure.

## Debugging Workflows

The integration must provide a consistent set of debugging operations.

### Session management

Support:

- Starting a debugging session.
- Attaching to an existing process where supported.
- Stopping an active session.
- Restarting a session where supported.
- Cleaning up terminated sessions.

### Breakpoint management

Support:

- Setting breakpoints.
- Removing breakpoints.
- Toggling breakpoints.
- Conditional breakpoints where supported.
- Logpoints where supported.

### Execution control

Support:

- Continue.
- Pause where supported.
- Step into.
- Step over.
- Step out.
- Terminate.

### Inspection

Support:

- Variable inspection.
- Expression evaluation.
- Call stack inspection.
- Thread inspection.
- Debug console or REPL interaction.
- Watch expressions where supported.

Not every operation is guaranteed to be available for every debugger adapter. Unsupported capabilities must be documented rather than simulated.

## Keymap Design

Debugging mappings must use a dedicated namespace and avoid conflicts with existing project mappings.

The final mappings must be reviewed against the repository's current keymap inventory before implementation.

### Candidate keymap namespace

`<leader>d` is the proposed debugging namespace.

| Mapping | Intended operation |
|---|---|
| `<leader>db` | Toggle breakpoint |
| `<leader>dB` | Set conditional breakpoint |
| `<leader>dc` | Continue execution |
| `<leader>di` | Step into |
| `<leader>do` | Step over |
| `<leader>du` | Step out |
| `<leader>dr` | Open or restart debugging session |
| `<leader>ds` | Stop debugging session |
| `<leader>dt` | Toggle debugging interface |
| `<leader>dw` | Inspect or manage watches |

These mappings are proposals, not approved registrations.

Final keymap admission requires collision analysis and interactive validation.

## External Dependencies

Stage 14 must maintain a clear distinction between plugin dependencies and external debugging tools.

| Dependency | Category | Installation responsibility |
|---|---|---|
| `nvim-dap` | Neovim plugin | Native plugin management |
| `nvim-dap-ui` | Optional Neovim plugin | Native plugin management |
| CodeLLDB / LLDB | Debugger | External installation |
| `debugpy` | Python debugger | External installation |
| Delve | Go debugger | External installation |
| Lua debugger | Lua debugging runtime | External installation |
| PowerShell Editor Services | PowerShell debugging integration | External installation |
| `vscode-js-debug` | JavaScript/TypeScript debugger | External installation |

The actual dependency list must be finalized after adapter selection.

### Dependency verification

Every selected debugger must have a documented verification command or procedure.

For executable-based adapters, verify:

- The executable exists.
- Neovim can discover it.
- The executable starts successfully.
- The adapter initializes correctly.
- The expected DAP capabilities are available.

Executable discovery alone does not establish a working debugging integration.

## Platform Compatibility

The configuration must preserve portability across Windows, Linux, and macOS.

### Windows

Validate:

- Executable discovery through PowerShell and Neovim.
- Windows-compatible debugger binaries.
- Adapter command and argument handling.
- Path handling.
- Runtime-specific dependencies.
- Launch and attach workflows.

### Linux and macOS

Validate:

- Native debugger availability.
- Executable permissions.
- Adapter command resolution.
- Runtime dependencies.
- Launch and attach workflows.

Platform-specific differences must remain isolated within adapter or dependency configuration rather than spreading throughout the shared DAP implementation.

## Validation Strategy

Validation must distinguish plugin loading, adapter registration, executable availability, and actual debugging behavior.

### 1. Configuration validation

Verify:

- Lua syntax.
- Module loading.
- Plugin registration.
- Adapter configuration.
- Language-specific configuration loading.
- Keymap registration.
- Compatibility with Neovim 0.12 or later.

### 2. Dependency validation

Verify:

- Required debugger executables are installed.
- Neovim can discover the executables.
- Required runtimes are available.
- Adapter commands and arguments are valid.
- Missing dependencies produce understandable diagnostics.

### 3. Adapter validation

For every selected adapter:

- Initialize a DAP session.
- Verify adapter communication.
- Confirm the expected runtime is detected.
- Validate launch or attach behavior.
- Verify session cleanup.

### 4. Interactive workflow validation

Test the following operations in a real Neovim session:

| Workflow | Expected result |
|---|---|
| Start debugging | Debugging session starts successfully |
| Attach | Neovim attaches to a supported target |
| Breakpoint | Execution stops at the configured breakpoint |
| Conditional breakpoint | Execution stops when the condition is satisfied |
| Continue | Execution resumes |
| Step into | Execution enters the selected function |
| Step over | Execution advances without entering the function |
| Step out | Execution returns to the caller |
| Variable inspection | Expected variable values are available |
| Expression evaluation | Supported expressions evaluate correctly |
| Call stack | Active stack frames are available |
| Termination | Debugging session terminates cleanly |

Unsupported operations must be identified per adapter.

### 5. Regression validation

Confirm that DAP integration does not break:

- Existing LSP attachment.
- Completion and snippets.
- Manual formatting.
- Diagnostics.
- Language-pack activation.
- Existing keymaps.
- Plugin loading.
- Startup behavior.

### 6. Automated validation

Run the repository's established checks:

```powershell
nvim --headless -u NONE -l scripts/check-syntax.lua
```

```powershell
nvim --headless -u init.lua -c "luafile scripts/smoke.lua"
```

```powershell
stylua --check .
```

Automated checks complement interactive testing. They do not replace actual debugger execution.

## Implementation Phases

Stage 14 should be implemented incrementally.

| Phase | Focus | Expected outcome |
|---|---|---|
| 01 | Architecture and plugin evaluation | Approved DAP architecture |
| 02 | Core DAP integration | Working DAP client |
| 03 | Adapter management | Explicit adapter registration |
| 04 | Language integrations | Selected language configurations |
| 05 | Keymaps and interface | Consistent debugging controls |
| 06 | External dependencies | Documented installation and verification |
| 07 | Interactive validation | Verified debugging workflows |
| 08 | Regression and closeout | Formal stage acceptance |

Each phase must preserve the established architecture and avoid introducing unrelated changes.

## Implementation Boundaries

The following rules govern Stage 14:

- Keep DAP configuration separate from LSP configuration.
- Do not assume that every supported language requires a debugger.
- Keep language-specific adapter configuration modular.
- Do not introduce Mason or silent debugger installation.
- Keep debugger executables separate from Neovim plugin installation.
- Avoid unnecessary modifications to existing language packs.
- Avoid introducing duplicate debugging interfaces.
- Do not make an optional debugging UI mandatory without architectural justification.
- Do not introduce future language support as part of the current Stage 14 scope.
- Plugin installation or loading alone does not establish working debugging capabilities.
- Adapter registration alone does not establish successful debugger communication.
- External executable discovery alone does not establish successful debugging.

## Documentation Requirements

The implementation must document:

- Selected DAP plugins and their responsibilities.
- Approved debugger adapters.
- Supported languages and runtimes.
- External executable dependencies.
- Platform-specific installation requirements.
- Adapter configuration.
- Debugging keymaps.
- Launch and attach workflows.
- Validation procedures.
- Known limitations.

Documentation must reflect the actual implemented and verified integrations rather than the initial candidate inventory.

## Completion Criteria

Stage 14 is considered complete only when all applicable requirements are satisfied.

### Architecture and integration

- [ ] DAP architecture and ownership boundaries are documented.
- [ ] Required plugins and dependencies are explicitly evaluated and selected.
- [ ] The selected DAP client integrates with the existing configuration.
- [ ] Debugger adapters are registered through the established architecture.
- [ ] Language-specific debugger configurations are modular.

### Dependencies

- [ ] Supported debugger adapters are identified.
- [ ] External debugger dependencies are documented.
- [ ] Required executables are available in the validation environment.
- [ ] Adapter initialization succeeds.
- [ ] Missing dependencies produce understandable diagnostics.

### Debugging workflows

- [ ] Project-owned debugging keymaps work without collisions.
- [ ] Launch workflows work where supported.
- [ ] Attach workflows work where supported.
- [ ] Breakpoints operate correctly.
- [ ] Execution stepping operates correctly.
- [ ] Variable inspection operates correctly.
- [ ] Call stack inspection operates correctly.
- [ ] Debugger termination and cleanup work correctly.

### Compatibility and regression

- [ ] Existing language workflows remain intact.
- [ ] Existing LSP functionality remains intact.
- [ ] Existing completion and formatting workflows remain intact.
- [ ] Plugin loading and startup behavior remain stable.
- [ ] Minimum supported Neovim compatibility is verified.
- [ ] Applicable platform compatibility is validated.

### Documentation and acceptance

- [ ] Selected plugins and adapters are documented.
- [ ] External dependency installation procedures are documented.
- [ ] Debugging keymaps are documented.
- [ ] Validation procedures are documented.
- [ ] Applicable syntax, smoke, and interactive tests pass.
- [ ] All defined stage acceptance requirements are satisfied.

## Stage Closeout

Stage 14 must remain open until its defined implementation and acceptance criteria are satisfied.

The completion of individual debugger integrations does not automatically establish completion of the entire stage.

Formal closeout requires verified debugging workflows, documented external dependencies, regression validation, and successful acceptance checks.

**Final status:** Planned. Implementation has not started.
