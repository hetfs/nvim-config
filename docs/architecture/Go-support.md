
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
| `config.keymaps.lua` | Go workflow mappings |
| `config.autocmds.lua` | Go buffer mapping registration |
| Tree-sitter | Parser registration and highlighting |
| External dependency management | Tool installation and health checks |

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

scripts/
└── smoke/
    └── suites/
        └── go.lua
```

The smoke-test location must follow the actual repository runner structure.

Do not introduce `lua/lsp/servers/gopls.lua` unless custom configuration becomes necessary. The upstream server definition is sufficient for the initial implementation.

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
| `gofmt` | Formatting | Required with Go |
| `gopls` | Language server | Required |
| `golangci-lint` | Linting | Required for selected lint workflow |
| `dlv` | Debugging | Deferred |
| `goimports` | Import organization | Not required |
| `gofumpt` | Alternative formatting | Not required |
| `gotestsum` | Enhanced test output | Optional |
| `govulncheck` | Vulnerability analysis | Optional |

Install external tools through the existing dependency-management layer.

The language pack must not install, upgrade or download executables.

Before implementation, identify the correct dependency manifest and health-check integration. Do not create another tool inventory.

## 8. Go Modules and Workspaces

Go modules and Go workspaces are different concepts.

- `go.mod` identifies a module.
- `go.work` defines a workspace containing multiple modules.
- A Git repository may contain one or multiple Go modules.

Use Go's environment information where appropriate:

```sh
go env GOMOD
go env GOWORK
```

Resolve these values from the current Go file's directory.

Do not assume that the workspace root is always a module root.

### Initial scope

The initial workflow operates on the module containing the current buffer.

The following workspace-wide behavior is deferred:

- Discovering every module in `go.work`.
- Executing commands across all modules.
- Aggregating errors and exit codes.
- Managing cancellation across multiple processes.

Do not claim that one `go test ./...` invocation from a workspace root tests every workspace module.

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

### Proposed buffer-local mappings

| Mapping | Description |
|---|---|
| `<leader>cr` | Go: Run package |
| `<leader>cb` | Go: Build module |
| `<leader>ct` | Go: Run tests |
| `<leader>cl` | Go: Lint module |
| `<leader>cc` | Go: Vet module |

Register mappings through the existing `config.keymaps.lua` and `config.autocmds.lua` conventions.

### Execution requirements

Workflow commands must:

- Validate the current buffer.
- Resolve the appropriate package or module directory.
- Check executable availability.
- Execute asynchronously.
- Capture stdout and stderr.
- Preserve process exit codes.
- Report startup errors.
- Report unsuccessful executions.
- Avoid blocking Neovim.
- Avoid unexpected project-file modifications.

Do not assume Neovim's current working directory is the Go module root.

## 10. Testing and Validation

Keep metadata tests independent of installed external executables.

### Language-pack tests

- [ ] Go pack discovery works.
- [ ] Activation is controlled by `config.languages.packs.go`.
- [ ] Disabled packs contribute no metadata.
- [ ] `gofmt` is registered correctly.
- [ ] Parser mappings are valid.
- [ ] gopls activates only when Go support is enabled.

### LSP tests

- [ ] Upstream gopls definition is available.
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
- [ ] gopls import organization works.
- [ ] golangci-lint runs from the correct module.
- [ ] Project lint configuration is respected.
- [ ] Automatic fixes are not applied.
- [ ] Missing tools produce useful diagnostics.

### Workflow tests

- [ ] Run uses the current package directory.
- [ ] Build uses the correct module root.
- [ ] Test uses the correct module root.
- [ ] Lint uses the correct module root.
- [ ] Vet uses the correct module root.
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
- [ ] Windows smoke tests pass.
- [ ] Lua syntax checks pass.
- [ ] StyLua checks pass.
- [ ] Markdown and Vale checks pass.

Do not claim completion until the implementation and relevant tests pass.

## 11. Implementation Order

Implement incrementally within Stage 13.

1. Inspect external dependency manifests and health checks.
2. Add `lua/langs/go.lua`.
3. Enable Go in `config.languages`.
4. Verify gopls activation and root detection.
5. Integrate and test `gofmt`.
6. Verify import organization.
7. Add the golangci-lint workflow.
8. Add run, build, test, lint and vet mappings.
9. Register Go buffer mappings.
10. Add smoke tests.
11. Update dependency documentation.
12. Run focused and regression tests.

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
- Standalone goimports.
- gofumpt as a default.
- Dedicated Go test-runner plugins.
- Automatic dependency installation.
- Go-specific root-management infrastructure.

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
