# Stage 13: Go Language Support

## 1. Purpose

This document defines the architecture, dependencies, implementation decisions, and validation requirements for Go language support in the Neovim configuration.

Go is an independent Stage 13 language pack. It follows the existing language registry, native Neovim LSP architecture, Conform formatting integration, Tree-sitter metadata contract, and centralized keymap conventions.

### Approved decisions

| Area | Decision |
|---|---|
| Language server | `gopls` |
| LSP management | Native Neovim LSP |
| LSP server definition | Existing `nvim-lspconfig` |
| Formatter | `gofmt` through Conform |
| Import organization | `gopls` code actions |
| Linter | `golangci-lint` |
| Static analysis | Native `go vet` command |
| Test runner | Native Go testing |
| Debugger | Deferred |
| Format on save | Disabled |
| Tool installation | External dependency management |

## 2. Architecture

### Ownership boundaries

| Component | Responsibility |
|---|---|
| `lua/langs/go.lua` | Go formatter and parser metadata, LSP activation |
| `nvim-lspconfig` | Supplies the `gopls` server definition |
| Native Neovim LSP | Server lifecycle and communication |
| Conform | Manual Go formatting |
| `gopls` | Language intelligence and import organization |
| `golangci-lint` | Static analysis |
| Go toolchain | Build, run, test, benchmark and vet |
| `config.languages.lua` | Language-pack activation |
| `config.keymaps.lua` | Go workflow mappings and command execution |
| `config.autocmds.lua` | Go buffer mapping registration |
| Tree-sitter | Parser registration and highlighting |
| External dependency management | Tool installation, when supported by the repository's shared dependency architecture |

The language pack declares Go-specific capabilities. Shared infrastructure owns execution and lifecycle management.

Do not introduce a second language registry, LSP manager, formatter framework, root detector, test runner or automatic installer.

### Target structure

```text
lua/
├── langs/
│   └── go.lua
├── config/
│   ├── languages.lua
│   ├── keymaps.lua
│   └── autocmds.lua
└── plugins/
    └── treesitter.lua
```

This is the immediate implementation scope. Go smoke-test integration is deferred until the repository's smoke-test modularization is complete. Its eventual location must follow the finalized runner architecture.

Do not introduce `lua/lsp/servers/gopls.lua` unless custom configuration becomes necessary. The upstream server definition is sufficient for the initial implementation.

### Shared infrastructure constraints

Preserve the existing contracts:

- Language packs are discovered through `langs`.
- Language activation is controlled by `config.languages`.
- Formatter metadata is collected through `langs.collect("formatters")`.
- Tree-sitter metadata is collected through the existing language registry.
- LSP activation uses native Neovim APIs.
- Buffer-local workflows are registered through centralized keymaps and autocmds.
- External tools are not installed automatically by Neovim.

Do not add Go-specific shared infrastructure when existing modules already provide the required capability.

## 3. Go Language Pack

Entry point:

`lua/langs/go.lua`

The language pack owns:

- Go formatter metadata.
- Tree-sitter parser mappings.
- `gopls` activation.

### Formatter metadata

```lua
formatters = {
  go = { "gofmt" },
}
```

Use `gofmt` as the canonical formatter.

Do not add `gofumpt` as a second default formatter.

### Tree-sitter metadata

| Filetype | Parser |
|---|---|
| `go` | `go` |
| `gomod` | `gomod` |
| `gowork` | `gowork` |
| `gotmpl` | `gotmpl` |

Declare these through `parser_by_filetype`.

The existing Tree-sitter integration owns parser registration, installation and highlighting.

Go workflow mappings should be registered only for Go source buffers with the `go` filetype. Supporting parser mappings for `gomod`, `gowork` and `gotmpl` does not automatically enable Go source workflows for those filetypes.

## 4. Language Server

### gopls

Use the official Go language server.

Activate it through:

```lua
vim.lsp.enable("gopls")
```

The server definition comes from `nvim-lspconfig`.

Do not use:

- `require("lspconfig").gopls.setup()`
- Mason or Mason-LSPConfig.
- A second LSP client.
- A custom server wrapper without a demonstrated requirement.

Start with upstream defaults. Preserve the upstream filetypes and root detection.

The Go language pack must activate `gopls` only when Go support is enabled.

### Import organization

Use the `gopls` `source.organizeImports` code action.

This supports:

- Adding missing imports.
- Removing unused imports.
- Sorting import declarations.

Use the existing `<leader>ca` code-action mapping.

Import organization remains manual. Do not modify imports automatically on save.

Standalone `goimports` is not required.

## 5. Formatting

Use Conform with `gofmt`.

| Operation | Owner |
|---|---|
| Source formatting | Conform |
| Import organization | gopls |
| Format-on-save | Existing user-controlled policy |

Preserve the existing formatting contract:

- Manual `:Format`.
- Existing `<leader>cf` mapping.
- Format-on-save disabled by default.
- No LSP formatting fallback.
- Language-pack-owned formatter defaults.
- User preferences in `config.languages`.

Do not configure Conform and gopls to compete for the same formatting operation.

Formatting must remain consistent with the existing formatter resolver. Do not introduce a Go-specific formatting framework.

## 6. Linting

### golangci-lint

Use `golangci-lint` as the primary linting tool.

Initial command:

```sh
golangci-lint run ./...
```

Execute it from the appropriate Go module root.

`golangci-lint` is a CLI tool, not an LSP server.

Use the standard linter selection unless a Go project supplies its own configuration.

Respect project-owned configuration files:

- `.golangci.yml`
- `.golangci.yaml`
- `.golangci.toml`
- `.golangci.json`

Do not create a global lint configuration in the Neovim repository.

For current v2 releases, use configuration version 2.

### go vet

Keep `go vet` available independently:

```sh
go vet ./...
```

Do not execute it automatically alongside every golangci-lint operation because the standard golangci-lint configuration already includes vet analysis.

### Automatic fixes

The initial lint workflow must be read-only.

Do not use:

```sh
golangci-lint run --fix
golangci-lint fmt
```

These operations can modify project files and conflict with the manual formatting policy.

## 7. External Dependencies

| Tool | Purpose | Priority |
|---|---|---|
| `go` | Go toolchain | Required |
| `gofmt` | Formatting | Included with Go |
| `gopls` | Language server | Required |
| `golangci-lint` | Linting | Required for the selected lint workflow |
| `dlv` | Debugging | Deferred |
| `goimports` | Import organization | Not required |
| `gofumpt` | Alternative formatting | Not required |
| `gotestsum` | Enhanced test output | Optional |
| `govulncheck` | Vulnerability analysis | Optional |

Install external tools outside Neovim.

The repository does not currently have a shared external dependency manifest or a dedicated dependency health module. Do not introduce either solely to support Go.

When the repository establishes these shared facilities, integrate Go dependencies into their existing contracts rather than creating Go-specific dependency management.

The language pack must not install, upgrade or download executables.

### Executable requirements

| Workflow | Executable |
|---|---|
| Run | `go` |
| Build | `go` |
| Test | `go` |
| Vet | `go` |
| Format | `gofmt` |
| LSP | `gopls` |
| Lint | `golangci-lint` |

The Go toolchain provides `gofmt`. The remaining external tools must be available through the user's environment.

Missing executables must produce useful diagnostics. Do not silently install dependencies or modify the user's environment.

## 8. Go Modules and Workspaces

Go modules and Go workspaces are different concepts.

- `go.mod` identifies a module.
- `go.work` defines a workspace containing multiple modules.
- A Git repository may contain one or multiple Go modules.

Use Go's environment information:

```sh
go env GOMOD
go env GOWORK
```

Resolve these values from the current Go file's directory.

Do not assume that the workspace root is always a module root.

### Initial scope

The initial workflow operates on the module containing the current buffer.

Use the current buffer's directory to resolve its module context. Do not depend on Neovim's current working directory.

For initial workflows:

- `go run .` executes from the current package directory.
- `go build ./...` executes from the resolved module root.
- `go test ./...` executes from the resolved module root.
- `golangci-lint run ./...` executes from the resolved module root.
- `go vet ./...` executes from the resolved module root.

The following workspace-wide behavior is deferred:

- Discovering every module in `go.work`.
- Executing commands across all modules.
- Aggregating errors and exit codes.
- Managing cancellation across multiple processes.

Do not claim that one `go test ./...` invocation from a workspace root tests every workspace module.

If module context cannot be resolved, report the problem rather than guessing a working directory.

## 9. Development Workflows

### Initial commands

| Workflow | Command | Working directory |
|---|---|---|
| Run package | `go run .` | Current package |
| Build module | `go build ./...` | Module root |
| Test module | `go test ./...` | Module root |
| Lint module | `golangci-lint run ./...` | Module root |
| Vet module | `go vet ./...` | Module root |

Execute commands using argument lists rather than concatenated shell strings.

### Buffer-local mappings

| Mapping | Description |
|---|---|
| `<leader>cr` | Go: Run package |
| `<leader>cb` | Go: Build module |
| `<leader>ct` | Go: Run tests |
| `<leader>cl` | Go: Lint module |
| `<leader>cc` | Go: Vet module |

Register mappings through the existing `config.keymaps.lua` and `config.autocmds.lua` conventions.

Register the mappings for Go source buffers only.

These mappings follow the existing language workflow convention and do not introduce global Go commands.

### Execution requirements

Workflow commands must:

- Validate that the buffer is valid.
- Require a saved Go source file.
- Resolve the appropriate package or module directory.
- Check executable availability.
- Execute asynchronously.
- Capture stdout and stderr.
- Preserve process exit codes.
- Report process startup errors.
- Report unsuccessful executions.
- Avoid blocking Neovim.
- Avoid unexpected project-file modifications.

Use `vim.system()` with argument arrays.

Do not construct shell commands by concatenating user-controlled paths or arguments.

### Output handling

Display command output in a dedicated scratch buffer.

The output should include:

- Executed command.
- Working directory.
- Standard output.
- Standard error, when present.
- Final process exit code.
- Signal information, when applicable.

Do not discard diagnostic output when a command fails.

A successful process should produce a success notification. A failed process should produce an error notification with its exit code.

Closing the output buffer must not interrupt or corrupt the editor's normal workflow.

## 10. Testing and Validation

Keep metadata tests independent of installed external executables.

The repository's smoke-test infrastructure is undergoing modularization. Do not add Go smoke-test suites or modify smoke-test files until that work is complete.

Until smoke-test modularization is complete, validate Go support using focused manual checks and the existing applicable syntax, formatting and regression checks.

### Language-pack tests

- [ ] Go pack discovery works.
- [ ] Activation is controlled by `config.languages.packs.go`.
- [ ] Disabled packs contribute no metadata.
- [ ] `gofmt` is registered correctly.
- [ ] Parser mappings are valid.
- [ ] `gopls` activates only when Go support is enabled.

### LSP tests

- [ ] Upstream `gopls` definition is available.
- [ ] Native LSP activation works.
- [ ] Go buffers attach correctly.
- [ ] Root detection works for modules and workspaces.
- [ ] Completion works.
- [ ] Diagnostics work.
- [ ] Navigation works.
- [ ] Import organization works.
- [ ] No duplicate LSP client is started.

### Formatting and lint tests

- [ ] Conform resolves `gofmt`.
- [ ] Manual formatting works.
- [ ] Format-on-save remains disabled.
- [ ] LSP formatting fallback remains disabled.
- [ ] `gopls` import organization works.
- [ ] `golangci-lint` runs from the correct module.
- [ ] Project lint configuration is respected.
- [ ] Automatic fixes are not applied.
- [ ] Missing tools produce useful diagnostics.

### Workflow tests

- [ ] Run uses the current package directory.
- [ ] Build uses the correct module root.
- [ ] Test uses the correct module root.
- [ ] Lint uses the correct module root.
- [ ] Vet uses the correct module root.
- [ ] Module detection works from nested package directories.
- [ ] Workspace context is handled without assuming the workspace root is a module root.
- [ ] Directories without a Go module produce useful diagnostics.
- [ ] stdout and stderr are captured.
- [ ] Exit codes are preserved.
- [ ] Failed process startup is handled.
- [ ] Workspace limitations are documented.

### Regression tests

- [ ] Existing Python tests pass.
- [ ] Existing C and C++ tests pass.
- [ ] Language registry tests pass.
- [ ] Formatter resolver tests pass.
- [ ] Tree-sitter tests pass.
- [ ] Lua syntax checks pass.
- [ ] StyLua checks pass.
- [ ] Markdown and Vale checks pass.

### Deferred smoke-test integration

After smoke-test modularization is complete:

- [ ] Add Go language-pack metadata coverage to the appropriate suite.
- [ ] Add Go activation and disabled-pack coverage.
- [ ] Add workflow registration coverage.
- [ ] Add executable-independent tests for module-context resolution where practical.
- [ ] Integrate the suite into the finalized runner.
- [ ] Run the complete applicable smoke-test suite.

Do not claim completion until the implementation and relevant tests pass.

## 11. Implementation Order

Implement incrementally within Stage 13.

1. Add `lua/langs/go.lua`.
2. Enable Go in `config.languages`.
3. Verify `gopls` activation and root detection.
4. Integrate and test `gofmt`.
5. Verify import organization.
6. Add the `golangci-lint` workflow.
7. Add run, build, test, lint and vet mappings.
8. Register Go buffer mappings.
9. Validate module detection from nested package directories.
10. Validate asynchronous command execution and output handling.
11. Perform focused manual validation.
12. Run applicable syntax, formatting and regression checks.
13. Update dependency documentation when the shared dependency-management architecture is available.
14. Add Go smoke tests after smoke-test modularization is complete.

Do not create a dependency manifest, health module or placeholder smoke-test directory solely for Go.

Do not implement debugging in this sequence.

## 12. Deferred Scope

Explicitly defer:

- Delve.
- nvim-dap Go adapter.
- Application and test debugging.
- Multi-module workspace orchestration.
- Format-on-save.
- Automatic import modification.
- Automatic lint fixes.
- Standalone `goimports`.
- `gofumpt` as a default.
- Dedicated Go test-runner plugins.
- Automatic dependency installation.
- Go-specific root-management infrastructure.
- Workspace-wide build and test orchestration.
- Go smoke-test integration before smoke-test modularization is complete.

Evaluate these separately after core Go support is stable.

## 13. References

- [Go documentation](https://go.dev/doc/)
- [Go command documentation](https://pkg.go.dev/cmd/go)
- [Go modules reference](https://go.dev/ref/mod)
- [Go workspaces](https://go.dev/doc/tutorial/workspaces)
- [gopls documentation](https://go.dev/gopls/)
- [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig)
- [golangci-lint](https://golangci-lint.run/)
- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)
- [Conform.nvim](https://github.com/stevearc/conform.nvim)

