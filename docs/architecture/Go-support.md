# Stage 14: Go Language Support

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
| Go toolchain | Build, run, test, benchmark, and vet |
| `lua/config/languages.lua` | Language-pack activation |
| `lua/config/keymaps.lua` | Go workflow mappings and command execution |
| `lua/config/autocmds.lua` | Go buffer mapping registration |
| Tree-sitter | Parser registration and highlighting |
| External dependency management | Tool installation, when supported by the repository's shared dependency architecture |

The language pack declares Go-specific capabilities. Shared infrastructure owns execution and lifecycle management.

Do not introduce a second language registry, LSP manager, formatter framework, root detector, test runner, or automatic installer.

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
- Language activation is controlled by `lua/config/languages.lua`.
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
- Go template filetype registration.
- Go template extension configuration for `gopls`.

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

The existing Tree-sitter integration owns parser registration, installation, and highlighting.

Go workflow mappings should be registered only for Go source buffers with the `go` filetype. Supporting parser mappings for `gomod`, `gowork`, and `gotmpl` does not automatically enable Go source workflows for those filetypes.

## 4. Language Server

### gopls

Use the official Go language server.

Activate it through:

```lua
vim.lsp.enable("gopls")
```

The server definition comes from `nvim-lspconfig`.

Do not use:

- `require("lspconfig").gopls.setup()`.
- Mason or Mason-LSPConfig.
- A second LSP client.
- A custom server wrapper without a demonstrated requirement.

Start with upstream defaults. Preserve the upstream filetypes and root detection.

The Go language pack must activate `gopls` only when Go support is enabled.

### Go template support

The Go language pack registers standard template extensions through Neovim's filetype association:

- `.tmpl`
- `.gotmpl`
- `.gohtml`

The configured `gopls` template extensions are:

```lua
templateExtensions = {
  "tmpl",
  "gotmpl",
  "gohtml",
}
```

The `.tmpl` association also covers compound extensions such as `.html.tmpl` and `.yaml.tmpl`.

The existing Tree-sitter integration provides the `gotmpl` parser.

Template support must remain within the existing Go language pack and shared infrastructure. Do not introduce a separate template language pack without a demonstrated architectural requirement.

### Template validation findings

The November 22, 2026 validation session confirmed the following:

- `gopls` attaches to Go source and template buffers.
- The configured template extensions are active.
- Go source diagnostics work.
- Malformed template syntax produces diagnostics.
- Tree-sitter loads the `gotmpl` parser for the tested template files.
- Named-template definition navigation works.
- Named-template reference discovery works.
- `.Title` references are found across multiple template files.
- `.Name` references are found across multiple template files.

#### Named-template definition

The fixture declares a named template:

```gotemplate
{{define "pageTitle"}}Go Templates{{end}}
```

It invokes that template with:

```gotemplate
{{template "pageTitle"}}
```

With the cursor positioned on `pageTitle` in the invocation, running:

```vim
:lua vim.lsp.buf.definition()
```

moved the cursor to the declaration.

**Result: Passed.**

#### Named-template references

With the cursor positioned on `pageTitle` in the declaration, running:

```vim
:lua vim.lsp.buf.references()
```

returned both the declaration and invocation:

```text
templates/index.tmpl|10 col 15-24| {{define "pageTitle"}}Go Templates{{end}}
templates/index.tmpl|11 col 17-26| {{template "pageTitle"}}
```

**Result: Passed.**

#### `.Title` cross-file references

Running `vim.lsp.buf.references()` on `.Title` returned four occurrences:

```text
templates/index.tmpl|5 col 15-20| <title>{{.Title}}</title>
templates/index.tmpl|8 col 12-17| <h1>{{.Title}}</h1>
templates/page.gotmpl|5 col 15-20| <title>{{.Title}}</title>
templates/page.gotmpl|9 col 16-21| <h1>{{.Title}}</h1>
```

**Result: Passed.**

#### `.Name` cross-file references

Running `vim.lsp.buf.references()` on `.Name` returned three occurrences:

```text
templates/config.yaml.tmpl|2 col 12-16| name: {{.Name}}
templates/email.gohtml|4 col 18-22| <h2>Hello {{.Name}},</h2>
templates/index.tmpl|9 col 20-24| <p>Welcome, {{.Name}}!</p>
```

**Result: Passed.**

#### Go struct-field definition navigation

Running `vim.lsp.buf.definition()` on `.Title` returned:

```text
no location found
```

This is distinct from named-template definition navigation.

Template fields such as `.Title` and `.Name` are field accesses on the template's data object. They are not Go variable declarations or named-template declarations.

The current test does not establish whether `gopls` can resolve a template field to the corresponding Go struct field. This behavior remains unresolved and requires a focused test using a known Go data structure and the actual template execution context.

Do not classify all template definition navigation as unsupported. Named-template definition navigation has already passed.

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
| Import organization | `gopls` |
| Format-on-save | Existing user-controlled policy |

Preserve the existing formatting contract:

- Manual `:Format`.
- Existing `<leader>cf` mapping.
- Format-on-save disabled by default.
- No LSP formatting fallback.
- Language-pack-owned formatter defaults.
- User preferences in `lua/config/languages.lua`.

Do not configure Conform and `gopls` to compete for the same formatting operation.

Formatting must remain consistent with the existing formatter resolver. Do not introduce a Go-specific formatting framework.

### Formatting validation

**Validation date:** 2026-11-22

Manual Go formatting through Conform is fully validated.

The validation used a temporary Go source file with deliberately inconsistent formatting.

The following checks passed:

- Conform recognized `gofmt` as the formatter for the Go buffer.
- The `gofmt` executable resolved correctly.
- Running `:Format` produced the expected Go formatting.
- `vim.bo.modified` returned `true` after formatting, confirming that the in-memory buffer changed.
- The formatted buffer was saved.
- Running `:!gofmt -d .\format_probe.go` produced no differences.
- The earlier Go fixture formatting checks also completed successfully.

The buffer-modified check is important because it confirms that Conform actually transformed the buffer. Formatter availability alone would not establish that.

Manual Conform formatting is validated.

No formatter implementation changes are required based on these results.

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

For current v2 releases, use configuration version 2.

Do not create a global lint configuration in the Neovim repository.

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

The language pack must not install, upgrade, or download executables.

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

### Windows Go tooling script

The Windows Go tooling script is implemented at:

`scripts/core/windows/go.ps1`

It manages and verifies the external Go development tools independently of Neovim.

#### Script responsibilities

- Detect Windows and PowerShell 7.
- Detect the existing Go toolchain.
- Resolve the Go binary directory.
- Verify `go`, `gofmt`, `gopls`, and `golangci-lint`.
- Install missing supported development tools.
- Update supported development tools when requested.
- Refresh the process and user PATH where required.
- Provide a check-only mode.

#### Supported execution modes

| Command | Responsibility |
|---|---|
| `.\go.ps1` | Detect and install missing supported tools |
| `.\go.ps1 -Check` | Verify existing tools without installing or updating |
| `.\go.ps1 -Update` | Update supported development tools |

The Go toolchain itself remains managed separately through the user's existing toolchain manager.

The script does not install Go dependencies through Neovim. It preserves the architecture's external dependency management boundary.

#### Windows validation results

**Validation date:** 2026-11-22

| Component | Verified version or result |
|---|---|
| Operating system | Windows, `windows/amd64` |
| PowerShell | 7.6.9 |
| Go | 1.23.0 |
| gofmt | Available from the Go 1.23.0 installation |
| gopls | 0.24.0 |
| golangci-lint | 2.15.0 |
| Normal execution | Passed |
| Check-only execution | Passed |

The script successfully detected the existing mise-managed Go installation and verified all four required executables.

The `-Check` mode confirmed that installation and updates were disabled during verification.

**Toolchain version note:** golangci-lint reports that it was built with Go 1.27.0. This is the version used to build golangci-lint, not the active Go toolchain. The active Go installation remains 1.23.0.

The Windows tooling script is considered validated. This status does not imply that the overall Go language pack or Stage 13 is complete.

## 8. Go Modules and Workspaces

Go modules and Go workspaces are different concepts.

- `go.mod` identifies a module.
- `go.work` defines a workspace containing one or more modules.
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

### Module and workspace validation results

The November 22 validation session confirmed:

| Test | Result |
|---|---|
| `GOMOD` from project root | Correct `go.mod` detected |
| `GOWORK` without a workspace file | Empty, as expected |
| `GOMOD` from nested directory | Parent module correctly detected |
| Neovim working directory | Correct project root |
| Nested Go buffer mapping | Registered |
| Nested module build | Passed, exit code 0 |
| Workspace discovery after `go work init` | Correct `go.work` detected |
| Workspace build before adding the module | Failed as expected because the workspace contained no modules |
| Workspace build after `go work use .` | Passed, exit code 0 |
| Workspace cleanup | Temporary `go.work` removed |
| `GOWORK` after cleanup | Empty, as expected |

The workspace test initially failed with:

```text
pattern ./...: directory prefix . does not contain modules listed in go.work or their selected dependencies
```

This was a workspace configuration issue, not evidence of a Neovim workflow defect.

After adding the current module with:

```powershell
go work use .
```

the workspace contained:

```go
go 1.23.0

use .
```

The nested build then completed successfully.

The temporary workspace file was removed after validation. The fixture was returned to module-only mode.

**Validation boundary:** Single-module workspace discovery and build execution have been tested. Multi-module workspace orchestration remains deferred.

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

Register mappings through the existing `lua/config/keymaps.lua` and `lua/config/autocmds.lua` conventions.

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

### Workflow validation results

The November 22 session confirmed:

- Go workflow mappings are registered for Go source buffers.
- The `FileType` autocmd for `go` is registered.
- The autocmd calls `require("config.keymaps").go(event.buf)`.
- All five mappings were confirmed with `:verbose nmap`.
- The nested Go buffer received the build mapping.
- The nested module build passed.
- The workspace-mode build passed after the module was added to `go.work`.
- Both successful build executions returned exit code `0`.

The following individual workflow executions still require validation through their Neovim mappings:

- Run package.
- Test module.
- Lint module.
- Vet module.

Successful standalone CLI checks do not automatically validate the corresponding Neovim workflow mappings.

## 10. Testing and Validation

### Validation checkpoint — 2026-11-22

The following results were confirmed during the Windows validation session. This is a progress snapshot, not a declaration that Stage 13 is complete.

### Environment

| Component | Verified version or result |
|---|---|
| Operating system | Windows, `windows/amd64` |
| PowerShell | 7.6.9 |
| Go toolchain | `go1.23.0` |
| Formatter | `gofmt` available |
| Language server | `gopls v0.24.0` |
| Linter | `golangci-lint v2.15.0` |
| Go template support | `templateExtensions` active with `tmpl`, `gotmpl`, and `gohtml` |

### Confirmed Windows Go tooling results

- [x] `scripts/core/windows/go.ps1` executes successfully.
- [x] `scripts/core/windows/go.ps1 -Check` completes successfully.
- [x] Windows and PowerShell 7.6.9 detection works.
- [x] Go 1.23.0 is detected.
- [x] The Go binary directory managed by mise is resolved correctly.
- [x] `gofmt` is detected in the Go installation directory.
- [x] `gopls v0.24.0` is detected.
- [x] `golangci-lint v2.15.0` is detected.
- [x] Check-only mode verifies dependencies without installing or updating them.
- [x] The script reports successful Go tooling verification.

### Confirmed Go fixture results

The following checks were performed in the `go-template-test` module:

- [x] `go fmt ./...` completed successfully.
- [x] `go vet ./...` completed successfully.
- [x] `go test ./...` completed successfully; the fixture currently has no test files.
- [x] `go run .` completed and rendered the four template fixtures.
- [x] `gofmt -d .\main.go` produced no differences after the saved file was formatted.
- [x] `golangci-lint run --verbose` completed successfully with **zero issues**.
- [x] The active golangci-lint configuration ran five linters: `errcheck`, `govet`, `ineffassign`, `staticcheck`, and `unused`.
- [x] The linter loaded the Go module and analyzed its packages successfully.

The successful lint run was performed from the fixture's module root.

### Confirmed Tree-sitter and template results

- [x] The `gotmpl` and `gowork` Tree-sitter parsers are installed.
- [x] The four template fixtures (`index.tmpl`, `page.gotmpl`, `email.gohtml`, and `config.yaml.tmpl`) are detected as `gotmpl`.
- [x] Tree-sitter loads the `gotmpl` parser for those template buffers.
- [x] `gopls` attaches to both `main.go` and the template buffers.
- [x] The active `gopls` client reports the configured `templateExtensions` values.
- [x] A deliberate Go type mismatch produced a `gopls` diagnostic.
- [x] A deliberately malformed template conditional produced a template diagnostic from `gopls`. The temporary malformed test was reverted.

### Confirmed Neovim workflow and LSP results

- [x] The Go `FileType` autocmd is registered.
- [x] The Tree-sitter `FileType` autocmd is registered for Go buffers.
- [x] The Go buffer autocmd invokes `require("config.keymaps").go(event.buf)`.
- [x] All five Go workflow mappings are registered.
- [x] The nested Go source buffer receives the Go workflow mappings.
- [x] The nested module build workflow succeeds with exit code `0`.
- [x] The workspace-mode build workflow succeeds with exit code `0` after the module is added to `go.work`.
- [x] Go LSP completion works when invoked from Insert mode.
- [x] Go module discovery works from the project root.
- [x] Go module discovery works from a nested directory.
- [x] Go workspace discovery works after creating `go.work`.
- [x] The temporary workspace configuration was removed successfully after testing.
- [x] `gotmpl` filetype detection works in the tested template buffers.
- [x] `gopls` attaches to the tested template buffer with the expected project root.
- [x] Named-template definition navigation works from the invocation to the declaration.
- [x] Named-template references return both the declaration and invocation.
- [x] `.Title` references are found across `index.tmpl` and `page.gotmpl`.
- [x] `.Name` references are found across `config.yaml.tmpl`, `email.gohtml`, and `index.tmpl`.

### Confirmed formatting results

- [x] Conform resolves `gofmt` for Go buffers.
- [x] The `:Format` command produces the expected Go formatting.
- [x] The in-memory buffer changes after `:Format`.
- [x] `vim.bo.modified` returns `true` after formatting.
- [x] The formatted buffer saves successfully.
- [x] `gofmt -d .\format_probe.go` produces no differences after saving.
- [x] The earlier Go fixture formatting check produces no differences for the saved `main.go`.

These results confirm both the Conform execution path and the saved-file formatting result.

### Pending or inconclusive results

- [ ] **Go struct-field definition navigation:** Running `vim.lsp.buf.definition()` on `.Title` returned `no location found`. Named-template definition navigation is confirmed working; this remaining test concerns resolving template data fields to Go struct declarations.
- [ ] **Import organization:** The `gopls` `source.organizeImports` code action has not yet been tested.
- [ ] **LSP root detection:** Module and workspace discovery through the Go environment and workflow have been tested. Native `gopls` root detection still requires independent confirmation.
- [ ] **LSP activation control:** Verify that `gopls` activates only when Go support is enabled.
- [ ] **Duplicate LSP clients:** Verify that no duplicate `gopls` client is started.
- [ ] **Run workflow:** The `<leader>cr` mapping has not yet been validated by executing a package.
- [ ] **Test workflow:** The `<leader>ct` mapping has not yet been validated by executing module tests.
- [ ] **Lint workflow:** The `<leader>cl` mapping has not yet been validated by executing `golangci-lint`.
- [ ] **Vet workflow:** The `<leader>cc` mapping has not yet been validated by executing `go vet`.
- [ ] **Failure handling:** Process startup errors, unsuccessful executions, and missing executables still require focused workflow validation.
- [ ] **Import modification policy:** Confirm that import organization remains manual and is not triggered on save.

Template definition and reference navigation must be assessed by symbol type. Named-template definition and reference navigation, along with cross-file template field references, have passed. Go struct-field definition navigation remains unresolved.

### Validation status

| Area | Status |
|---|---|
| Windows Go tooling script | Validated |
| Go toolchain and executable detection | Validated |
| Check-only mode | Validated |
| Go fixture linting | Passed, zero issues |
| Go source and template diagnostics | Validated |
| Go LSP completion | Validated |
| Go workflow mapping registration | Validated |
| Nested module discovery and build | Validated |
| Single-module workspace discovery and build | Validated |
| Manual Conform formatting | Validated |
| Saved-file formatting verification | Passed |
| Named-template definition navigation | Validated |
| Named-template reference navigation | Validated |
| `.Title` cross-file references | Validated |
| `.Name` cross-file references | Validated |
| Go struct-field definition navigation | Unresolved |
| Import organization | Pending |
| Individual run, test, lint, and vet workflows | Pending |
| Go language-pack implementation | Under validation |
| Stage 13 | Incomplete |

**Important boundary:** Windows Go tooling validation, manual Conform formatting validation, and the tested template navigation features are complete. They must remain separate from the overall Go language-pack validation.

### Current testing checkpoint

The formatting investigation and the named-template and template-reference navigation investigation are complete.

The next active work should focus on the remaining Go language-pack requirements.

Proceed in this order:

1. Test `gopls` import organization through the existing code-action mapping.
2. Verify native `gopls` root detection for modules and workspaces.
3. Verify that `gopls` activation follows the Go language-pack enablement setting.
4. Confirm that only one `gopls` client is started.
5. Test the run, test, lint, and vet workflow mappings individually.
6. Test workflow failure handling and missing-executable diagnostics.
7. Investigate Go struct-field definition navigation separately, using a known Go data structure and its template execution context.
8. Run applicable syntax, formatting, and regression checks.

Do not change the language-pack architecture or introduce a custom LSP handler until the remaining tests identify a specific limitation or configuration issue.

### Language-pack tests

- [ ] Go pack discovery works.
- [ ] Activation is controlled by `config.languages.packs.go`.
- [ ] Disabled packs contribute no metadata.
- [x] `gofmt` is registered and resolves correctly.
- [x] Parser mappings are declared and the tested Go template parsers load.
- [ ] `gopls` activates only when Go support is enabled.

### LSP tests

- [ ] Upstream `gopls` definition is available.
- [x] Native LSP activation works.
- [x] Go buffers attach correctly.
- [ ] Native LSP root detection works for modules and workspaces.
- [x] Completion works.
- [x] Diagnostics work for Go source and Go templates.
- [x] Named-template definition navigation works.
- [x] Named-template reference navigation works.
- [x] Template field references work across files.
- [ ] Go struct-field definition navigation resolves to Go declarations.
- [ ] Import organization works.
- [ ] No duplicate LSP client is started.

### Formatting and lint tests

- [x] Conform resolves `gofmt`.
- [x] Manual `:Format` execution is confirmed.
- [x] The in-memory Go buffer changes after formatting.
- [x] The modified-buffer state is confirmed.
- [x] Saved-file formatting verification passes.
- [ ] Format-on-save remains disabled.
- [ ] LSP formatting fallback remains disabled.
- [ ] `gopls` import organization works.
- [x] `golangci-lint` executes successfully in the Go fixture.
- [ ] `golangci-lint` runs from the correct module through the Neovim workflow.
- [ ] Project lint configuration is respected through the Neovim workflow.
- [ ] Automatic fixes are not applied.
- [x] Missing-tool verification is covered by the Windows tooling script's executable checks.

### Workflow tests

- [ ] Run uses the current package directory.
- [x] Build uses the correct module root.
- [x] Build works from a nested Go source buffer.
- [x] Build works in the tested single-module workspace configuration.
- [ ] Test uses the correct module root through the Neovim workflow.
- [ ] Lint uses the correct module root through the Neovim workflow.
- [ ] Vet uses the correct module root through the Neovim workflow.
- [x] Module discovery works from nested package directories.
- [x] Single-module workspace context is handled after the module is added to `go.work`.
- [ ] Directories without a Go module produce useful diagnostics.
- [ ] stdout and stderr are captured in both successful and failed workflow executions.
- [x] Exit codes are preserved in the tested build workflows.
- [ ] Failed process startup is handled.
- [ ] Missing executables produce useful diagnostics.
- [x] Multi-module workspace orchestration remains explicitly deferred.

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
2. Enable Go in `lua/config/languages.lua`.
3. Verify `gopls` activation and root detection.
4. Integrate and test `gofmt`.
5. Verify import organization.
6. Add the `golangci-lint` workflow.
7. Add run, build, test, lint, and vet mappings.
8. Register Go buffer mappings.
9. Validate module detection from nested package directories.
10. Validate asynchronous command execution and output handling.
11. Perform focused manual validation.
12. Run applicable syntax, formatting, and regression checks.
13. Update dependency documentation when the shared dependency-management architecture is available.
14. Add Go smoke tests after smoke-test modularization is complete.

The Windows Go tooling script has been implemented and validated independently. Manual Conform formatting has also been validated. Named-template navigation and cross-file template field references have passed their focused tests. None of these results replaces the remaining Neovim language-pack implementation and testing steps.

Do not create a dependency manifest, health module, or placeholder smoke-test directory solely for Go.

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
- Automatic dependency installation through Neovim.
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
- [gopls template support](https://go.dev/gopls/features/template)
- [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig)
- [golangci-lint](https://golangci-lint.run/)
- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)
- [Conform.nvim](https://github.com/stevearc/conform.nvim)
