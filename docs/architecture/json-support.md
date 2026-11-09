# JSON Support

Part of the `data` core language pack (Stage 13). Covers JSON, JSONC, and JSON5.

- **Status:** Core implementation and interactive validation passed
- **Language group:** JSON
- **Language-pack location:** `lua/langs/data.lua`
- **LSP support:** JSON and JSONC
- **Formatting:** JSON, JSONC, and JSON5 through Prettier and Conform
- **Tree-sitter:** JSON, JSONC, and JSON5
- **Plugin admission:** No new plugins approved

## 1. Goals

- Native-first: use Neovim's built-in `vim.lsp.config()` and `vim.lsp.enable()` APIs, native filetype detection where sufficient, and native Tree-sitter integration.
- Support JSON, JSONC, and JSON5 as distinct filetypes with their respective syntax rules.
- Use Prettier through the existing Conform integration for formatting.
- Keep LSP formatting disabled. Conform is the sole formatting integration.
- Use manual formatting through the existing formatting command.
- Keep format-on-save disabled by default.
- Introduce no new required plugins.
- Provide JSON and JSONC syntax validation through the JSON language server.
- Keep JSON Schema validation separate from syntax validation.
- Keep SchemaStore optional and disabled unless explicitly approved.
- Keep external executable installation separate from Neovim startup.

## 2. Filetype distinctions

The three formats retain their syntax differences.

| Filetype | Syntax | Typical use |
|---|---|---|
| `json` | Strict JSON | Package manifests, API data, JSON documents |
| `jsonc` | JSON with comments | VS Code settings and configuration files |
| `json5` | Extended JSON syntax | Human-maintained configuration files |

### 2.1 JSON

Standard JSON does not allow:

- Comments.
- Single-quoted strings.
- Unquoted object keys.
- Trailing commas.

### 2.2 JSONC

JSONC supports comments. Trailing-comma behavior depends on the application consuming the file.

Common examples include:

- `tsconfig.json`
- `jsconfig.json`
- `.vscode/settings.json`
- `.vscode/launch.json`

The actual filetype assigned to these special filenames must be checked separately. Testing a file named `test.jsonc` does not establish that every `.json` configuration filename is detected as JSONC.

### 2.3 JSON5

JSON5 extends JSON with additional syntax, including:

- Unquoted object keys.
- Single-quoted strings.
- Trailing commas.
- Multiline strings.
- Hexadecimal numbers.
- Additional numeric representations.

JSON5 must not be assigned the ordinary JSON filetype merely because its content resembles JSON.

## 3. Components

| Concern | Choice | Kind |
|---|---|---|
| Language server | `jsonls` | LSP server |
| Server definition | `nvim-lspconfig` | Existing plugin; definitions only |
| Server executable | `vscode-json-language-server` | External tool |
| Server package | `vscode-langservers-extracted` | npm package |
| Formatter | Prettier through Conform | External tool and existing integration |
| JSON parser | `json` | Tree-sitter |
| JSONC parser | `json` | Tree-sitter parser mapped to `jsonc` |
| JSON5 parser | `json5` | Tree-sitter |
| Schema validation | JSON Language Server | Built-in server capability |
| Schema catalogue | SchemaStore | Optional integration |

### Support boundary

The LSP implementation targets `json` and `jsonc`.

JSON5 receives its own filetype, Tree-sitter parser, and Prettier formatter. JSON5 LSP validation is intentionally excluded from the current baseline.

The Tree-sitter configuration maps the `jsonc` filetype to the `json` parser. There is no separate `jsonc` parser in the installed parser registry.

## 4. Files and responsibilities

| File | Responsibility |
|---|---|
| `lua/langs/data.lua` | YAML, JSON, JSONC, JSON5, jq, and TOML metadata and configuration |
| `lua/langs/init.lua` | Existing automatic language-pack discovery |
| `lua/plugins/treesitter.lua` | JSON-family parser highlighting |
| `lua/plugins/lsp.lua` | Existing LSP server-definition dependency |
| `lua/config/format.lua` | Existing Conform integration |
| `docs/json-support.md` | JSON support decisions and validation record |
| `docs/languages.md` | Data-language pack status |

No separate JSON registry or additional language loader is introduced.

Filetype overrides should only be added if testing shows that Neovim's existing detection does not correctly identify the intended files.

## 5. Dependencies

### 5.1 External tools

| Tool | Purpose | Installation |
|---|---|---|
| `vscode-json-language-server` | JSON and JSONC LSP | npm package `vscode-langservers-extracted` |
| `prettier` | JSON, JSONC, and JSON5 formatting | npm package `prettier` |

Installation command:

```powershell
npm install --global vscode-langservers-extracted prettier
```

### 5.2 Verification

Check the language server executable:

```powershell
Get-Command vscode-json-language-server
```

The language server is an LSP process, not a conventional command-line utility. Invoking it with `--version` does not provide a valid version check and can produce a connection-input error.

Neovim launches it through its configured stdio transport.

Check Prettier:

```powershell
prettier --version
```

Windows installations should expose the corresponding npm command wrappers on PATH.

### 5.3 External dependency policy

- Installation is explicit.
- No npm installation occurs during Neovim startup.
- The language pack does not install external tools.
- The Windows installer owns dependency installation and verification.
- Exact versions should be pinned after the selected versions have been recorded and tested.

### 5.4 Current dependency verification

- `vscode-json-language-server` is available through the global npm command wrapper.
- The language server successfully starts through Neovim.
- Prettier successfully formats JSON, JSONC, and JSON5.
- The installed `nvim-lspconfig` checkout provides `lsp/jsonls.lua`.
- Installed `nvim-lspconfig` revision: `77b7432d`.

## 6. Implementation

### 6.1 Language-pack configuration

JSON support belongs in the existing data-language pack:

`lua/langs/data.lua`

Do not create another language pack solely for JSON.

The formatter metadata includes:

```lua
formatters = {
  json = { "prettier" },
  jsonc = { "prettier" },
  json5 = { "prettier" },
},
```

These entries are implemented and have passed formatter discovery and actual formatting through the existing Conform integration.

The JSON language-server configuration uses Neovim's native LSP API:

```lua
enable("jsonls", {
  filetypes = {
    "json",
    "jsonc",
  },

  settings = {
    json = {
      validate = {
        enable = true,
      },

      format = {
        enable = false,
      },

      schemas = {},
    },
  },
})
```

The server definition is supplied by the already-installed `nvim-lspconfig` plugin.

The configuration does not compete with Conform for formatting.

JSON5 is deliberately excluded from the JSON language-server filetypes.

### 6.2 Conform formatting

Use the existing formatter metadata in `lua/langs/data.lua`.

| Filetype | Formatter | Availability | Actual formatting |
|---|---|---|---|
| `json` | `prettier` | Passed | Passed |
| `jsonc` | `prettier` | Passed | Passed |
| `json5` | `prettier` | Passed | Passed |

Conform remains the only formatting integration.

Formatting policy:

- Manual formatting through the existing `:Format` command.
- No automatic formatting on save.
- No LSP formatting fallback.
- No separate JSON formatting plugin.

Prettier's default behavior is used. Project-wide formatting overrides should be introduced only when there is a demonstrated requirement.

### 6.3 Filetype detection

Use Neovim's existing filetype detection wherever possible.

The representative test files used during implementation include:

| Filename | Expected filetype | Validation status |
|---|---|---|
| `test.json` | `json` | Confirmed |
| `test.jsonc` | `jsonc` | Confirmed |
| `test.json5` | `json5` | Confirmed |
| `package.json` | `json` | Not separately tested |
| `data.json` | `json` | Not separately tested |
| `tsconfig.json` | `jsonc` | Pending |
| `jsconfig.json` | `jsonc` | Pending |
| `.vscode/settings.json` | `jsonc` | Pending |
| `.vscode/launch.json` | `jsonc` | Pending |

The test files confirm that the three explicit extensions are handled independently. They do not establish special filename detection for every JSONC configuration file.

If a mismatch is found, evaluate a narrowly scoped `vim.filetype.add()` rule.

Do not add broad filename or pattern rules without testing their effect on ordinary JSON files.

### 6.4 Tree-sitter

Use the existing Tree-sitter plugin and native highlighting API.

Required parsers:

```lua
{
  "json",
  "json5",
}
```

The `json` parser handles both `json` and `jsonc` through the installed `nvim-treesitter` filetype mapping.

There is no separate `jsonc` parser to install.

The existing Tree-sitter FileType integration includes:

```lua
pattern = {
  "lua",
  "python",
  "yaml",
  "json",
  "jsonc",
  "json5",
},
```

Preserve all existing parser and Windows configuration.

Parser installation remains explicit. Do not introduce startup parser installation.

Tree-sitter folding continues to use Neovim's existing native folding configuration.

## 7. JSON Schema support

JSON Schema validation is a capability of the JSON Language Server. It does not require a separate LSP server.

The implementation distinguishes between:

1. JSON syntax validation.
2. JSON Schema validation.
3. Schema discovery and association.

These are related but separate capabilities.

### 7.1 Syntax validation

The JSON Language Server validates JSON and JSONC syntax.

Examples of invalid input include:

- Missing quotation marks around property names.
- Missing commas.
- Unclosed strings.
- Invalid JSON values.

**Status:** JSON and JSONC syntax diagnostics passed using deliberately invalid buffer contents.

### 7.2 Schema validation

JSON Schema provides structural and semantic validation.

For example, a schema can define:

- Required properties.
- Property types.
- Allowed values.
- Nested object structures.
- Array item requirements.

Schema validation must be tested independently from syntax validation.

**Status:** Deferred. JSON and JSONC syntax diagnostics passing does not establish that schema associations or schema diagnostics work.

### 7.3 Schema association

Preferred initial strategy:

- Project-owned JSON Schema files.
- Explicit schema associations where necessary.
- `$schema` references in supported JSON documents.

A project may organize schemas as follows:

```text
project/
├── .schemas/
│   └── app-config.schema.json
├── config/
│   └── app.json
└── package.json
```

Example schema reference:

```json
{
  "$schema": "../.schemas/app-config.schema.json",
  "name": "example",
  "enabled": true
}
```

The JSON Language Server must be tested to confirm that the reference resolves correctly in the intended project layout.

### 7.4 SchemaStore

SchemaStore is an optional schema catalogue.

It is not required for:

- JSON syntax validation.
- JSONC syntax validation.
- Prettier formatting.
- Local project-owned schemas.

Do not add `b0o/schemastore.nvim` to the required plugin inventory.

Do not dynamically require SchemaStore from the LSP configuration unless the optional integration has been explicitly approved and its loading behavior has been verified.

The current schema configuration remains:

```lua
schemas = {},
```

SchemaStore remains disabled.

## 8. Formatting and LSP policy

The existing formatting policy remains unchanged:

| Feature | Default |
|---|---|
| Manual Prettier formatting | Enabled |
| Format-on-save | Disabled |
| LSP formatting | Disabled |
| LSP formatting fallback | Disabled |
| Conform as formatter | Enabled |
| JSON5 LSP validation | Not included |

JSON formatting must always resolve to Prettier through Conform.

The JSON Language Server must not register as a competing formatter.

## 9. Validation

Validation is performed incrementally.

### 9.1 Filetype detection

The explicit test files confirmed:

- `test.json` uses `json`.
- `test.jsonc` uses `jsonc`.
- `test.json5` uses `json5`.

Special filename detection for `tsconfig.json`, `jsconfig.json`, and `.vscode` configuration files remains to be evaluated.

### 9.2 LSP attachment

The active JSON and JSONC buffers were inspected using Neovim's native LSP client API.

**Verified:**

- `jsonls` attaches to a JSON buffer.
- `jsonls` attaches to a JSONC buffer.
- The active client reports `json` and `jsonc` as configured filetypes.
- JSON validation is enabled.
- JSON language-server formatting is disabled.

JSON5 is intentionally excluded from this LSP attachment test.

### 9.3 Syntax diagnostics

Invalid JSON and JSONC samples were tested.

**Verified:**

- Invalid JSON produces error diagnostics.
- Invalid JSONC produces error diagnostics.
- Both filetypes attach to `jsonls`.
- Both filetypes receive validation diagnostics.

The JSONC test produced a diagnostic with:

```text
source: jsonc
message: Value expected
severity: 1
```

The JSON test also produced an error diagnostic for invalid syntax.

These results establish syntax validation, not JSON Schema validation.

### 9.4 Formatting

Prettier formatter discovery and actual formatting were tested for all three filetypes.

**Verified through Conform:**

| Filetype | Formatter discovered | Available | `:Format` |
|---|---|---|---|
| `json` | `prettier` | Yes | Passed |
| `jsonc` | `prettier` | Yes | Passed |
| `json5` | `prettier` | Yes | Passed |

The formatter command resolved to `prettier.cmd` on Windows.

All three formatting operations completed without errors.

The manual `:Format` command was tested. Separate verification of the `<leader>cf` keymap remains outstanding.

### 9.5 Tree-sitter

The Stage 08 Tree-sitter configuration includes JSON, JSONC, and JSON5.

The validated parser configuration is:

| Filetype | Parser |
|---|---|
| `json` | `json` |
| `jsonc` | `json` |
| `json5` | `json5` |

JSONC uses the JSON parser through the installed filetype mapping.

The existing Stage 08 parser and highlighting validation covered JSON, JSONC, and JSON5.

### 9.6 JSON Schema validation

Use a small project-owned JSON Schema and a corresponding JSON document.

Verify:

- The schema resolves.
- Required-property violations are reported.
- Incorrect property types are reported.
- Correct documents produce no schema diagnostics.

**Status:** Pending. Do not mark schema support complete until these checks pass.

### 9.7 Repository integration checks

The following checks passed after the data-language pack implementation:

| Check | Command | Result |
|---|---|---|
| StyLua | `stylua --check lua/langs/data.lua` | Passed |
| Lua syntax | `nvim --headless -u NONE -l scripts/check-syntax.lua` | Passed — 33 Lua files |
| Full smoke suite | `nvim --headless -u init.lua -c "luafile scripts/smoke.lua"` | Passed |
| Diff whitespace | `git diff --check` | Passed |

The smoke test passed all reported checks, including:

- Stage 06 plugin loading.
- Stage 07 navigation and editing registration.
- Stage 09 LSP and language-pack configuration.
- Stage 10 completion, snippets, and pairing.
- Stage 11 formatting and linting.
- Stage 12 Git, project, and session registration.
- Native grep and quickfix.
- Native commenting.
- Module failure contract.

The smoke test ran successfully on Neovim 0.12.6.

These are repository-level integration results. They do not replace individual JSON Schema or special filename detection tests.

## 10. Troubleshooting

| Symptom | Possible cause | Action |
|---|---|---|
| `jsonls` does not attach | Server executable missing or not on PATH | Install `vscode-langservers-extracted` and verify the executable |
| Comments produce JSON errors | Buffer detected as `json` instead of `jsonc` | Inspect filetype detection and add a narrow override if needed |
| JSON5 diagnostics are missing | JSON5 is outside the current LSP scope | Use the JSON5 parser and Prettier; evaluate a compatible validator separately |
| Formatting does nothing | Prettier missing or unavailable | Check `prettier --version` and Conform formatter discovery |
| Schema diagnostics are missing | Schema not associated or not resolved | Verify the schema reference and JSON Language Server behavior |
| LSP formatting competes with Prettier | Server formatting was enabled | Keep `format.enable = false` |
| Parser is unavailable | Required parser has not been installed | Install it explicitly through the existing Tree-sitter workflow |

## 11. Out of scope

The current JSON baseline does not include:

- JSON Lines (`.jsonl`) support.
- `jq` or `jless` integration as part of the JSON implementation.
- Automatic dependency installation.
- Automatic parser installation.
- Format-on-save.
- LSP formatting.
- Required SchemaStore integration.
- A separate JSON5 language server.
- JSON5 LSP validation.
- Additional JSON-specific plugins.

The data pack's separate jq workflow is documented and implemented independently.

These capabilities can be evaluated without expanding the current JSON baseline.

## 12. Completion criteria

The JSON-family baseline requires:

- JSON, JSONC, and JSON5 to remain distinct filetypes.
- JSON and JSONC to attach to `jsonls`.
- JSON and JSONC syntax diagnostics to work.
- JSON, JSONC, and JSON5 formatting to work through Prettier and Conform.
- JSON, JSONC, and JSON5 Tree-sitter parsing to work.
- LSP formatting to remain disabled.
- Manual formatting to work through the existing command.
- JSON Schema validation to be implemented and verified or explicitly recorded as deferred.

The implementation and core validation criteria have passed.

Remaining work is limited to:

1. Special filename detection for common JSONC configuration files.
2. Manual formatting keymap verification.
3. JSON Schema association and diagnostic validation, if included in the approved scope.

JSON5 LSP validation remains outside the baseline unless independently implemented and tested.

## 13. Decision summary

| Area | Decision |
|---|---|
| Language pack | Existing `lua/langs/data.lua` |
| LSP | `jsonls` for JSON and JSONC |
| LSP API | Native `vim.lsp.config()` and `vim.lsp.enable()` |
| Server definition | Existing `nvim-lspconfig` |
| Formatter | Prettier through Conform |
| JSON parser | `json` |
| JSONC parser | `json` mapped to `jsonc` |
| JSON5 parser | `json5` |
| JSON5 LSP | Deferred |
| Schema validation | JSON Language Server capability; testing pending |
| Schema management | Project-owned schemas preferred |
| SchemaStore | Optional, disabled by default |
| Format-on-save | Disabled |
| LSP formatting | Disabled |
| New required plugins | None |

**Current status:** JSON and JSONC LSP attachment and syntax diagnostics have passed. JSON, JSONC, and JSON5 formatting through Conform has passed. Tree-sitter support and repository integration checks have passed. Special filename detection, manual formatting keymap verification, and JSON Schema validation remain outstanding.
