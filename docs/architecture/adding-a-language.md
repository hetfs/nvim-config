# Adding a New Language

This guide defines the standard process for integrating a new programming language into `nvim-config`.

The objective is to make language support predictable, modular, and consistent with the project's native-first architecture.

**Core principle:** Add only the configuration required by the language. Reuse existing infrastructure before introducing new modules, dependencies, or abstractions.

## 1. Architecture and ownership

Language support is distributed across existing project modules. Each module has a specific responsibility.

| Component | Responsibility |
|---|---|
| `lua/langs/` | Language-specific configuration and metadata |
| `lua/langs/init.lua` | Language-pack discovery, activation, initialization, and metadata aggregation |
| `lua/config/languages.lua` | Explicit language-pack activation and user preferences |
| `lua/config/keymaps.lua` | Central ownership of user-facing keymaps and language workflows |
| `lua/config/autocmds.lua` | Buffer-specific configuration and workflow registration |
| `lua/config/lsp.lua` | Shared native LSP attachment behavior |
| `lua/plugins/lsp.lua` | Installation of nvim-lspconfig server definitions |
| `lua/plugins/treesitter.lua` | Tree-sitter parser registration and installation |
| `lua/config/format.lua` | Formatter resolution and formatting policy |
| `lua/plugins/conform.lua` | Conform plugin setup |

### Ownership rules

1. Language-specific configuration belongs in `lua/langs/`.
2. Shared infrastructure belongs in `lua/config/` or `lua/plugins/`, according to its responsibility.
3. User-facing keymaps remain centralized in `lua/config/keymaps.lua`.
4. Language packs must not duplicate shared LSP attachment behavior.
5. External tools must not be installed automatically by language packs.
6. Do not introduce a new abstraction when an existing module already provides the required functionality.

## 2. Understand the language-pack contract

The language registry discovers files in `lua/langs/` automatically.

A language pack:

- Must have a filename matching its language name.
- Must return a Lua table.
- May declare metadata.
- May implement an optional `setup()` function.
- Must be explicitly enabled in `lua/config/languages.lua`.

The registry provides two important operations:

- `require("langs").setup()` initializes enabled language packs.
- `require("langs").collect(field)` aggregates metadata from enabled language packs.

Metadata keys must have exactly one owning language pack. Duplicate ownership causes an error.

Metadata-only packs do not need a `setup()` function.

## 3. Step 1: Inspect existing implementations

Before creating a language pack:

1. Inspect a language pack with similar requirements.
2. Review the current language registry.
3. Inspect the formatter configuration.
4. Inspect Tree-sitter integration.
5. Review existing LSP configuration and attachment behavior.
6. Review language workflow conventions in `config.keymaps`.
7. Inspect the relevant autocmd registrations.

Prefer an existing implementation with similar characteristics.

For example:

- A language with only formatting and Tree-sitter support may need no custom workflow.
- A language with an LSP server may need a small `setup()` function.
- A language with build and test commands may need buffer-local workflow mappings.

Do not copy an entire language pack without understanding which parts are actually necessary.

## 4. Step 2: Create the language pack

Create:

`lua/langs/<language>.lua`

A metadata-only language pack can follow this structure:

```lua
-- Language-specific configuration.

return {
  formatters = {
    -- Filetype = { formatter }
  },

  parser_by_filetype = {
    -- Filetype = parser
  },
}
```

Only include metadata supported by the current registry and consumed by the relevant integration.

For example, the existing registry supports:

- `formatters`
- `parser_by_filetype`
- `parser_dependencies_by_filetype`

Do not add arbitrary metadata fields without first establishing a consumer and a clear ownership contract.

### Optional setup function

When language-specific initialization is required, add `setup()`:

```lua
local M = {}

function M.setup()
  -- Language-specific initialization.
end

return M
```

Use this function for language-specific setup such as native LSP activation.

Do not put shared configuration or unrelated workflow implementations in this function.

## 5. Step 3: Enable the language pack

Edit:

`lua/config/languages.lua`

Add an explicit activation entry:

```lua
packs = {
  -- Existing language packs.
  example = true,
}
```

The registry only initializes explicitly enabled packs.

Use `false` when a pack should be available in the repository but disabled by default.

Do not modify `lua/langs/init.lua` to register a new language. Automatic discovery is already implemented.

## 6. Step 4: Configure native LSP when needed

First determine whether the language requires an LSP server.

The project uses:

- `nvim-lspconfig` for maintained server definitions.
- Neovim's native LSP API for configuration and activation.
- `lua/config/lsp.lua` for shared attachment behavior.

A typical language pack can enable a server directly:

```lua
local M = {}

function M.setup()
  vim.lsp.enable("example_server")
end

return M
```

Before using a server:

1. Confirm that its definition exists in the installed nvim-lspconfig version.
2. Confirm the server executable is available on `PATH`.
3. Check whether its default configuration is sufficient.
4. Add custom configuration only when there is a demonstrated requirement.

Do not use the legacy `require("lspconfig").server.setup()` interface.

Do not create a custom file under `lua/lsp/servers/` simply because a language is new.

A custom server configuration is justified only when the language requires behavior that cannot be expressed cleanly through the existing native configuration.

Do not duplicate shared `LspAttach` behavior or LSP keymaps inside language packs.

## 7. Step 5: Configure formatting when needed

Formatter metadata belongs in the language pack:

```lua
return {
  formatters = {
    example = {
      "example_formatter",
    },
  },
}
```

The formatter key must match the relevant Neovim filetype.

The formatter identifier must match the corresponding Conform formatter definition.

The existing formatting architecture provides:

- Language-pack defaults.
- User-defined formatter preferences.
- `preferred`.
- `stop_after_first`.
- `formatters_only`.
- Manual formatting through `:Format`.
- Optional format-on-save, disabled by default.

Do not create language-specific formatting logic when the existing Conform integration already supports the formatter.

Do not introduce LSP formatting as an implicit fallback. The project explicitly uses `lsp_format = "never"`.

Do not enable format-on-save for a new language without an explicit architectural decision.

## 8. Step 6: Configure Tree-sitter when needed

Declare parser mappings in the language pack:

```lua
return {
  parser_by_filetype = {
    example = "example",
  },
}
```

If a filetype requires additional parsers, use the existing dependency metadata:

```lua
return {
  parser_by_filetype = {
    example = "example",
  },

  parser_dependencies_by_filetype = {
    example = {
      "another_parser",
    },
  },
}
```

The primary parser enables highlighting. Additional parsers are installed as dependencies without being started on the current buffer.

Before declaring a parser:

1. Confirm the parser name used by nvim-treesitter.
2. Confirm the actual Neovim filetype.
3. Check whether the filetype and parser names differ.
4. Check whether additional parsers are genuinely required.

Do not modify `lua/plugins/treesitter.lua` for ordinary language additions. It already collects metadata from enabled language packs.

## 9. Step 7: Add language workflows only when justified

Some languages need more than LSP, formatting, and syntax highlighting.

Examples include:

- Running a source file.
- Building a project.
- Running tests.
- Running a linter.
- Running a type checker.
- Executing language-specific project commands.

Before adding workflows, identify which commands are useful and how they should resolve the project root.

Add user-facing mappings to:

`lua/config/keymaps.lua`

Use a language-specific method following the existing conventions:

```lua
function M.example(bufnr)
  -- Register buffer-local language mappings.
end
```

Register the method through an appropriate `FileType` autocmd in:

`lua/config/autocmds.lua`

### Workflow requirements

- Use buffer-local mappings.
- Provide meaningful descriptions for every mapping.
- Use argument lists instead of concatenated shell commands.
- Execute commands from the correct project directory.
- Prefer asynchronous execution for potentially long-running processes.
- Capture standard output and standard error.
- Preserve and report the process exit status.
- Handle missing executables and process startup failures.
- Avoid blocking Neovim's UI.
- Respect project-specific configuration files.
- Never silently install missing tools.

Do not add workflow mappings that duplicate existing native commands or plugin functionality without a clear benefit.

## 10. Step 8: Handle external dependencies

Language packs configure Neovim. They do not manage the installation of external tools.

Examples of external dependencies include:

- Language runtimes.
- Language servers.
- Formatters.
- Linters.
- Debug adapters.
- Build tools.

For each required dependency, document:

1. Its purpose.
2. Whether it is required or optional.
3. The command or functionality that depends on it.
4. How users can verify its availability.

Use the project's established dependency-management architecture when it exists.

Do not introduce Mason, automatic installation, or a new dependency manifest solely to support one language.

A missing external executable should produce a useful diagnostic rather than an automatic installation attempt.

## 11. Step 9: Add buffer-specific configuration only when necessary

Some languages need buffer-specific settings, such as:

- Indentation.
- Folding.
- Text wrapping.
- Comment behavior.
- Language-specific mappings.

Place these settings in the appropriate `FileType` autocmd in `lua/config/autocmds.lua`.

Keep the configuration focused.

Do not create an autocmd merely to repeat settings already handled by Neovim or an existing plugin.

## 12. Step 10: Validate the integration

Validation must cover the actual behavior introduced by the language pack.

### Static validation

- Lua syntax checks pass.
- Formatting checks pass.
- Language registry discovery succeeds.
- Pack activation is valid.
- Metadata aggregation succeeds.
- No duplicate metadata ownership exists.

### LSP validation

When LSP is enabled:

- The server executable is available.
- Neovim recognizes the server configuration.
- The server attaches to the intended filetype.
- Shared LSP mappings work.
- Diagnostics are delivered correctly.

### Formatting validation

When a formatter is configured:

- The formatter executable is available.
- Conform recognizes the formatter.
- Manual `:Format` works.
- The formatter produces valid output.
- User preferences still resolve correctly.

### Tree-sitter validation

When a parser is configured:

- The parser mapping is correct.
- The parser can be installed.
- Neovim can load it.
- Highlighting starts for the intended filetype.
- Additional parser dependencies are handled correctly.

### Workflow validation

When workflows are introduced:

- Commands run from the intended directory.
- Project-root detection works.
- Standard output and standard error are captured.
- Exit codes are preserved.
- Missing executables are handled.
- Failure cases do not block Neovim.

### Smoke tests

Add or update smoke coverage according to the project's current smoke-test architecture.

Do not bypass the existing modularization effort or introduce a separate test runner for one language.

A syntax check alone does not prove that an LSP server, formatter, parser, or workflow works correctly.

## 13. Step 11: Document the language integration

Document the language's:

- Supported filetypes.
- Language server.
- Formatter.
- Tree-sitter parser.
- Required external tools.
- Optional external tools.
- Available workflows and keymaps.
- Project-specific configuration requirements.
- Known limitations.

Keep implementation documentation consistent with actual code.

Do not document features that have not been implemented and validated.

## 14. Files that normally change

A typical integration should touch only the files needed for its capabilities.

| File | When to modify |
|---|---|
| `lua/langs/<language>.lua` | Every new language pack |
| `lua/config/languages.lua` | Every language that should be enabled |
| `lua/config/keymaps.lua` | Only when adding language workflows |
| `lua/config/autocmds.lua` | Only when adding buffer-specific behavior |
| `docs/architecture/` | When adding or updating architectural guidance |
| Tests or smoke suites | According to the current test architecture |

Normally, these files should remain unchanged:

- `init.lua`
- `lua/langs/init.lua`
- `lua/config/lsp.lua`
- `lua/config/format.lua`
- `lua/plugins/lsp.lua`
- `lua/plugins/treesitter.lua`

Change shared infrastructure only when the new language exposes a genuine limitation in the existing contract.

## 15. Definition of done

A language integration is complete when:

- [ ] The language pack follows the registry contract.
- [ ] The pack is explicitly enabled or intentionally disabled.
- [ ] Required LSP configuration is correct.
- [ ] Formatter metadata is correct, when applicable.
- [ ] Tree-sitter metadata is correct, when applicable.
- [ ] Language workflows follow existing conventions, when applicable.
- [ ] External dependencies are documented.
- [ ] Buffer-specific configuration is justified.
- [ ] Static validation passes.
- [ ] Relevant behavior has been tested.
- [ ] Documentation matches the implementation.
- [ ] No unnecessary shared abstractions or duplicated logic were introduced.

## 16. Architectural principles to preserve

Every new language integration must respect these project principles:

1. **Native first:** Prefer Neovim's native capabilities and APIs.
2. **Explicit activation:** A discovered language pack is not automatically enabled.
3. **Modular ownership:** Each component owns a clearly defined responsibility.
4. **Minimum installation:** Add only the dependencies required for the requested functionality.
5. **No silent installation:** External tools remain outside the language-pack lifecycle.
6. **Deterministic behavior:** Pack discovery, metadata ownership, and configuration resolution must remain predictable.
7. **Shared infrastructure:** Reuse central LSP, formatting, Tree-sitter, and workflow infrastructure.
8. **Incremental development:** Add one capability at a time and validate it.
9. **Evidence-based configuration:** Introduce custom behavior only when a concrete requirement justifies it.
10. **Documentation and testing:** Treat both as part of the integration, not as optional cleanup.

---

**Final rule:** A new language should extend the existing architecture, not create a parallel architecture.
