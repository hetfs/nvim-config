# Neotest Integration

## 1. Purpose

Provide a modular, cross-platform test-running and test-discovery integration for Neovim using [Neotest](https://github.com/nvim-neotest/neotest).

The integration must support multiple testing frameworks while preserving the project's native-first architecture, modularity, and maintainability.

The implementation must work on Windows, Linux, and macOS without platform-specific patches to third-party plugins.

## 2. Architectural principles

1. **Native-first:** Use Neovim APIs and existing project infrastructure where possible.
2. **Modular:** Separate plugin installation, adapter construction, and keymaps.
3. **Explicit dependencies:** Declare all required plugins and their dependencies.
4. **Cross-platform:** Avoid assumptions about path separators, executable locations, shells, and process behavior.
5. **Project-aware:** Allow adapters to identify their applicable project roots.
6. **Failure isolation:** A failure in one optional adapter must not prevent unrelated adapters from loading.
7. **No unnecessary abstractions:** Do not introduce custom registries, compatibility frameworks, or redundant modules.
8. **Upstream integrity:** Do not modify installed third-party plugin source.
9. **Testability:** Every adapter must be independently validated for discovery, execution, and result reporting.

## 3. Supported components

### Core

- `nvim-neotest/neotest`
- `nvim-lua/plenary.nvim`
- `nvim-neotest/nvim-nio`

### Adapters

| Language | Adapter | Testing framework |
|---|---|---|
| Python | `neotest-python` | pytest |
| JavaScript | `neotest-jest` | Jest |
| JavaScript | `neotest-vitest` | Vitest |
| Go | `neotest-go` | Go test |
| Rust | `neotest-rust` | Cargo |
| Lua | `neotest-plenary` | Plenary |
| Lua | `neotest-busted` | Busted |
| C/C++ | `neotest-ctest` | CTest |
| Bash | `neotest-bash` | Bash |

All adapters are optional integration components. Their absence or initialization failure must not disable the Neotest core or unrelated adapters.

## 4. File architecture

The integration must use the following structure:

```text
lua/
├── config/
│   └── keymaps.lua
└── plugins/
    └── neotest/
        ├── init.lua
        └── adapters.lua
```

### `lua/plugins/neotest/init.lua`

Responsibilities:

- Declare Neotest core dependencies and adapter plugins using `vim.pack`.
- Load the adapter builder.
- Initialize Neotest.
- Configure only integration-wide Neotest behavior.
- Avoid language-specific implementation logic.

### `lua/plugins/neotest/adapters.lua`

Responsibilities:

- Construct the supported adapters.
- Apply framework-specific adapter options.
- Validate adapter initialization.
- Isolate optional adapter failures.
- Return the successfully initialized adapters.

The module must not install plugins, define keymaps, or execute tests.

### `lua/config/keymaps.lua`

Responsibilities:

- Define all Neotest keymaps.
- Keep mappings consistent with the existing leader-key architecture.
- Avoid references to nonexistent modules.
- Use Neotest's public API.

## 5. Adapter behavior

Each adapter must be evaluated independently.

The integration must establish:

- Whether the adapter can be loaded.
- Whether its project root can be identified.
- Whether its test files can be discovered.
- Whether its test positions can be parsed.
- Whether its test command can be constructed.
- Whether tests execute successfully.
- Whether results are returned and reflected in Neotest's state.

An adapter must not be considered functional merely because its Lua module loads.

### Project-root behavior

- Respect each adapter's native root-detection behavior.
- Avoid registering unrelated project roots.
- Avoid treating Neovim's configuration directory or installed plugin directories as user test projects.
- Handle Windows long paths and short-path aliases carefully.
- Do not introduce global path rewriting without a demonstrated requirement.

### Parser dependencies

Adapters that use Tree-sitter must have their required parsers available.

Missing parsers must produce clear, adapter-specific diagnostics. An unrelated adapter's parser failure must not silently prevent other adapters from functioning.

## 6. Keymap contract

Preserve the existing Neotest mapping conventions:

| Mapping | Action |
|---|---|
| `<leader>tf` | Run current file |
| `<leader>ta` | Attach to running test |
| `<leader>tT` | Run all tests from working directory |
| `<leader>tr` | Run nearest test |
| `<leader>tl` | Run last test |
| `<leader>ts` | Toggle test summary |
| `<leader>to` | Open test output |
| `<leader>tO` | Toggle output panel |
| `<leader>tS` | Stop test execution |
| `<leader>tw` | Toggle test watching |

Mappings must call supported Neotest APIs directly.

## 7. Cross-platform requirements

The implementation must not assume:

- Windows uses the same path representation as Neovim buffers.
- `python` and `python3` resolve identically.
- Executables are installed globally.
- A shell is available or behaves identically across operating systems.
- Every project uses the same test command.
- Every adapter uses the same discovery strategy.

Use Neovim's filesystem and process APIs where appropriate. Prefer adapter-native executable resolution and configuration.

## 8. Error handling and observability

- Report adapter loading failures with the adapter name.
- Distinguish discovery failures from execution failures.
- Preserve useful process exit codes and output.
- Do not suppress result-parser failures.
- Avoid silently converting failed result reads into successful empty results.
- Keep diagnostics actionable and scoped to the failing adapter.

## 9. Acceptance criteria

### Core integration

- [ ] Core dependencies load successfully.
- [ ] Neotest initializes with available adapters.
- [ ] An unavailable optional adapter does not disable other adapters.
- [ ] All keymaps resolve to valid Neotest APIs.

### Adapter validation

For every adapter:

- [ ] Module loads.
- [ ] Project root is identified correctly.
- [ ] Test files are detected.
- [ ] Test positions are discovered.
- [ ] Build specification is valid.
- [ ] Test process executes.
- [ ] Results are parsed.
- [ ] Neotest state reflects the test outcome.

### Cross-platform validation

- [ ] Windows path handling.
- [ ] Linux path handling.
- [ ] macOS path handling.
- [ ] Executable resolution.
- [ ] Process execution and output capture.

### Regression validation

- [ ] Existing unrelated Neovim functionality remains unchanged.
- [ ] No installed plugin source is modified.
- [ ] No duplicate test-runner implementation is introduced.
- [ ] No unnecessary modules or frameworks are added.

## 10. Implementation sequence

1. Validate the specification against the existing Neovim architecture.
2. Implement plugin installation and core initialization.
3. Implement adapter construction.
4. Add Neotest keymaps.
5. Validate core discovery and execution.
6. Validate each adapter independently.
7. Validate interactions between adapters.
8. Perform cross-platform review.
9. Update the integration documentation with verified behavior.

## 11. Definition of done

The integration is complete when all nine adapters pass their applicable discovery, execution, and result-reporting tests, the core remains operational when optional adapters fail, and the implementation meets the project's cross-platform and architectural requirements.
