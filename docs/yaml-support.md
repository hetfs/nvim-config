# YAML Support

- **Status:** Implemented and interactively validated
- **Language group:** YAML
- **Build order:** 3 of 11
- **Implementation status:** Core YAML support and four YAML-based variants validated
- **Language-pack location:** `lua/langs/data.lua`
- **Plugin admission:** No new plugins approved

## 1. Purpose and scope

This document defines YAML support for Stage 13 of the Neovim configuration.

The implementation follows the project's native-first language-pack architecture. It reuses existing shared infrastructure and keeps external dependencies separate from Neovim plugin installation.

The supported YAML filetypes are:

- Standard YAML: `yaml`
- Docker Compose: `yaml.docker-compose`
- Ansible: `yaml.ansible`
- GitLab CI: `yaml.gitlab`
- Helm values: `yaml.helm-values`

The implementation provides:

- Filetype-specific language-server configuration.
- YAML Language Server attachment.
- Syntax diagnostics through YAML Language Server.
- Completion and hover through the language server.
- Formatting through the existing Conform.nvim integration.
- Tree-sitter parsing and highlighting.
- Explicit external dependency installation and verification.
- Interactive validation of the supported filetypes.

Helm templates, including `.tpl` files, and chezmoi templates such as `.yaml.tmpl` remain outside the supported scope.

## 2. Dependency selection and status

| Capability | Selected dependency / approach | Status |
|---|---|---|
| Language server | YAML Language Server (`yamlls`) | Installed and tested |
| Formatter | Prettier | Installed and tested |
| Tree-sitter parser | `yaml` | Installed and tested |
| Schema validation | YAML Language Server built-in JSON Schema support | Available; configuration deferred |
| Schema management | Project-owned schemas, modelines, and explicit associations | Recommended; implementation pending |
| SchemaStore | Optional automatic schema catalogue | Deferred |
| Standalone YAML linter | None; `yamllint` may be evaluated separately | Deferred |

### 2.1 Verified environment

The following environment details were confirmed during implementation:

| Component | Verified value |
|---|---|
| Neovim | 0.12.6 |
| YAML Language Server | Installed and executable |
| Prettier | Installed and executable |
| Tree-sitter parser | `yaml` |

The language server is invoked using:

```text
yaml-language-server --stdio
```

The formatter is invoked through Conform using the Windows-resolved executable:

```text
prettier.cmd
```

These dependencies are external tools, not Neovim plugins.

The implementation reuses the maintained `nvim-lspconfig` server definition. Neovim's native LSP APIs remain responsible for configuration and activation.

## 3. Language-pack architecture

YAML support is implemented in the shared data-language pack:

`lua/langs/data.lua`

The data pack also provides JSON, JSONC, JSON5, jq, and TOML support. Those capabilities have their own configuration and validation requirements.

The YAML implementation follows the existing language registry conventions.

### 3.1 Language-server configuration

The data-language pack uses Neovim's native APIs:

- `vim.lsp.config()` for language-server configuration.
- `vim.lsp.enable()` for language-server activation.

The selected server identifier is:

```lua
yamlls
```

The configured filetypes are:

```lua
filetypes = {
  "yaml",
  "yaml.docker-compose",
  "yaml.ansible",
  "yaml.gitlab",
  "yaml.helm-values",
},
```

Relevant settings:

```lua
settings = {
  redhat = {
    telemetry = {
      enabled = false,
    },
  },

  yaml = {
    validate = true,

    -- Formatting is handled by Conform.
    format = {
      enable = false,
    },

    -- SchemaStore integration is intentionally deferred.
    schemaStore = {
      enable = false,
    },
  },
}
```

The language server's formatting capability is disabled because Prettier is the selected formatter through Conform.

The following behavior has been verified:

- The `yamlls` configuration is registered.
- The server starts successfully.
- The server attaches to standard YAML buffers.
- The server attaches to all four additional YAML filetypes.
- Invalid standard YAML produces diagnostics.
- Valid standard YAML produces zero diagnostics.
- Completion and hover work through the configured LSP workflow.

Attachment was independently checked for all five supported filetypes. The diagnostic, completion, and hover tests establish the standard YAML behavior; they should not be interpreted as separate exhaustive feature tests for every dialect.

Shared LSP attachment behavior remains in `lua/config/lsp.lua`.

### 3.2 Filetype detection

The supported filetypes are:

| Format | Neovim filetype |
|---|---|
| Standard YAML | `yaml` |
| Docker Compose | `yaml.docker-compose` |
| Ansible | `yaml.ansible` |
| GitLab CI | `yaml.gitlab` |
| Helm values | `yaml.helm-values` |

The language pack explicitly declares these filetypes for YAML Language Server configuration and formatter metadata.

The Tree-sitter configuration maps the additional YAML filetypes to the YAML parser.

The following mappings were verified:

```lua
vim.treesitter.language.get_lang("yaml.docker-compose")
-- yaml

vim.treesitter.language.get_lang("yaml.ansible")
-- yaml

vim.treesitter.language.get_lang("yaml.gitlab")
-- yaml

vim.treesitter.language.get_lang("yaml.helm-values")
-- yaml
```

These mappings establish parser resolution. They do not imply that each dialect has a separate Tree-sitter grammar.

### 3.3 Formatting

Prettier is the selected formatter for all supported YAML filetypes.

The data-language pack declares the formatter through the shared formatter metadata contract:

```lua
formatters = {
  yaml = { "prettier" },
  ["yaml.docker-compose"] = { "prettier" },
  ["yaml.ansible"] = { "prettier" },
  ["yaml.gitlab"] = { "prettier" },
  ["yaml.helm-values"] = { "prettier" },
},
```

The shared formatting infrastructure resolves formatter preferences and invokes Conform.nvim.

Relevant shared modules:

- `lua/config/format.lua`
- `lua/config/languages.lua`

The implementation preserves these policies:

- Conform.nvim remains the sole formatting integration.
- Format-on-save remains disabled by default.
- Language-server formatting is disabled for YAML.
- Prettier is selected through the language-pack formatter registry.
- Formatter availability is checked independently of language-server attachment.

The following formatter checks passed:

| Filetype | Formatter discovery | Actual `:Format` execution |
|---|---|---|
| `yaml` | Passed | Passed |
| `yaml.docker-compose` | Passed | Passed |
| `yaml.ansible` | Passed | Passed |
| `yaml.gitlab` | Passed | Passed |
| `yaml.helm-values` | Passed | Passed |

For every listed filetype, Conform resolved `prettier` as available and completed formatting without errors.

This confirms that the shared formatter resolver handles each declared YAML variant.

### 3.4 Tree-sitter

The YAML parser is integrated with the existing Tree-sitter configuration.

The existing configuration includes the supported YAML filetypes in its explicit highlighting configuration.

The implementation preserves Windows-specific support for:

- Built-in Windows `tar`.
- GCC parser compilation when `CC` is not already configured.

The YAML parser is installed explicitly through the installed `nvim-treesitter` API:

```lua
require("nvim-treesitter").install({ "yaml" }):wait(300000)
```

Parser installation is not performed during Neovim startup.

The following behavior has been verified:

- The YAML parser is installed.
- Neovim can inspect the YAML parser.
- Standard YAML highlighting works.
- Additional YAML filetypes resolve to the YAML parser.
- `vim.treesitter.start()` succeeds through the existing highlighting configuration.

The additional filetype-to-parser mappings were verified independently.

### 3.5 Indentation and editing behavior

Prettier produced two-space YAML indentation in the formatting tests.

This confirms the formatter's observed output, not a separate buffer-local indentation policy.

A dedicated YAML indentation configuration has not been established.

Any future YAML-specific indentation or folding configuration must remain scoped to YAML buffers and must not change unrelated filetypes.

Tree-sitter-based folding is not a prerequisite for the current YAML baseline.

## 4. Schema support and management

YAML Language Server includes built-in JSON Schema support. No additional plugin, language server, or schema-management package is required for this capability.

The current configuration explicitly disables automatic SchemaStore integration:

```lua
schemaStore = {
  enable = false,
},
```

YAML syntax validation remains enabled independently:

```lua
validate = true,
```

The distinction is important:

- YAML syntax validation checks whether the document is valid YAML.
- JSON Schema validation checks whether the document's structure and values conform to an associated schema.
- Disabling SchemaStore does not disable the language server's underlying JSON Schema validation capability.

Schema validation is available in the selected language server, but schema association and validation have not yet been implemented or tested in this configuration.

### 4.1 Recommended schema-management strategy

Use project-owned schemas as the default, with explicit associations where necessary.

The recommended priority is:

1. **Project-owned local schemas:** Preferred for project-specific configuration and predictable offline validation.
2. **YAML modelines:** Preferred when an individual YAML file should declare its own schema association.
3. **Explicit `yaml.schemas` associations:** Use when mappings should be centrally configured for a workspace.
4. **SchemaStore:** Optional enhancement, subject to a separate decision.

Keep project-specific schemas in the repositories that own the corresponding YAML configuration. This allows schemas to be version-controlled, reviewed, and shared without adding project-specific rules to the global Neovim configuration.

### 4.2 YAML modelines

YAML Language Server supports schema declarations through YAML modelines.

Example:

```yaml
# yaml-language-server: $schema=../.schemas/app-config.schema.json

name: example
enabled: true
```

This approach is useful when a schema belongs to a particular file and the association should remain with that file.

### 4.3 Explicit schema associations

YAML Language Server also supports the `yaml.schemas` setting.

Illustrative example:

```lua
schemas = {
  ["./.schemas/app-config.schema.json"] = {
    "config/app.yaml",
  },
}
```

Use this approach when associations need to be managed centrally rather than declared in individual YAML files.

Relative paths in workspace-level schema associations require consideration of the workspace root and multi-root workspace behavior.

Do not add illustrative paths or associations to the active configuration until they have been tested against a representative project.

### 4.4 SchemaStore policy

SchemaStore provides a catalogue of schemas for common configuration formats.

Automatic SchemaStore integration remains disabled initially.

Before enabling it, evaluate:

- Which schemas are available for the formats in scope.
- How automatic associations are selected.
- Remote catalogue and schema retrieval requirements.
- Behavior when network access is unavailable.
- How explicit project schemas interact with catalogue associations.
- Whether automatic associations introduce unexpected validation behavior.

Do not make Neovim startup or ordinary YAML editing depend on successful remote catalogue retrieval.

### 4.5 Schema implementation gates

Schema support should be introduced as a separate extension to the completed YAML baseline.

The implementation sequence should be:

1. Create a small local JSON Schema for a representative YAML configuration.
2. Associate it through a YAML modeline.
3. Test valid and invalid values and confirm the expected diagnostics.
4. Test an explicit workspace-level `yaml.schemas` association.
5. Evaluate remote schema retrieval and its failure behavior.
6. Evaluate SchemaStore separately.
7. Document the approved schema-management policy and validation results.

**Current decision:** Built-in JSON Schema support is available. Project-owned schemas and modelines are the preferred approach. Explicit associations are supported when needed. SchemaStore remains optional and disabled. Schema implementation and validation are pending.

## 5. Dependencies and installation

External tools remain separate from Neovim plugin installation.

The YAML implementation requires:

| Dependency | Installation method | Verification |
|---|---|---|
| YAML Language Server | Global npm installation | `yaml-language-server --version` |
| Prettier | Global npm installation | `prettier --version` |
| YAML Tree-sitter parser | Explicit `nvim-treesitter` installation | Inspect parser availability in Neovim |

Schema validation uses the existing YAML Language Server. It does not require an additional executable.

The npm installation commands are:

```powershell
npm install --global yaml-language-server
npm install --global prettier
```

Verification:

```powershell
yaml-language-server --version
prettier --version
```

The parser installation command is:

```lua
require("nvim-treesitter").install({ "yaml" }):wait(300000)
```

The implementation must not:

- Install executables automatically during Neovim startup.
- Assume that a documented dependency is installed.
- Add a package manager or dependency-installation plugin solely for YAML support.
- Add a standalone linter before its purpose and integration have been reviewed.
- Treat parser installation as proof of language-server or formatter availability.

Future installation documentation should follow the project's established dependency-management conventions.

## 6. Linting and diagnostics

The implementation uses YAML Language Server diagnostics.

No standalone YAML linter has been selected or installed.

A standalone linter such as `yamllint` may be evaluated later, but it is not part of the current dependency baseline.

The following standard YAML diagnostic behavior has been verified:

| Test | Result |
|---|---|
| Language server starts and attaches | Passed |
| Invalid YAML produces diagnostics | Passed |
| Valid YAML produces zero diagnostics | Passed |
| Correcting invalid YAML clears diagnostics | Passed |

The additional YAML filetypes have passed language-server attachment checks. Separate diagnostic test cases for every dialect have not been recorded.

A future linter proposal must account for:

- Stage 11's existing linting-integration decision.
- Whether standalone linting is required beyond LSP diagnostics.
- Executable and runtime requirements.
- Filetype coverage.
- Diagnostic overlap and duplication.
- A repeatable invocation and validation procedure.

Installing a CLI linter does not automatically authorize integrating it into Neovim.

## 7. Validation requirements and results

YAML support must be validated against representative files. A successful module load is insufficient evidence of a working language pack.

### 7.1 Completed validation

| Area | Verification | Result |
|---|---|---|
| Language-pack metadata | `langs.collect("formatters")` | Passed |
| Formatter resolution | `config.format.resolve()` | Passed |
| Standard YAML LSP | `yamlls` attachment | Passed |
| Docker Compose LSP | `yamlls` attachment | Passed |
| Ansible LSP | `yamlls` attachment | Passed |
| GitLab CI LSP | `yamlls` attachment | Passed |
| Helm values LSP | `yamlls` attachment | Passed |
| Standard YAML diagnostics | Invalid and valid YAML samples | Passed |
| Standard YAML completion | Interactive completion | Passed |
| Standard YAML hover | Interactive hover | Passed |
| YAML formatter discovery | All five supported filetypes | Passed |
| YAML formatting | `:Format` for all five supported filetypes | Passed |
| Tree-sitter parser | YAML parser installation and inspection | Passed |
| Additional parser mappings | Four YAML variant filetypes | Passed |
| Highlighting startup | `vim.treesitter.start()` | Passed |
| Visual highlighting | Interactive editor inspection | Passed |

### 7.2 Repository-level validation

The following repository checks also passed after the data-language pack implementation:

| Check | Command | Result |
|---|---|---|
| StyLua | `stylua --check lua/langs/data.lua` | Passed |
| Lua syntax | `nvim --headless -u NONE -l scripts/check-syntax.lua` | Passed — 33 Lua files |
| Full smoke suite | `nvim --headless -u init.lua -c "luafile scripts/smoke.lua"` | Passed |
| Diff whitespace | `git diff --check` | Passed |

The smoke test included the existing Stage 06, 07, 09, 10, 11, and 12 checks, native grep and quickfix, native commenting, and the module failure contract.

These are repository-level results. They should not be interpreted as individual YAML dialect diagnostic tests.

### 7.3 Deferred and outstanding work

| Area | Status |
|---|---|
| JSON Schema validation | Available in YAML Language Server; configuration and testing deferred |
| Schema management | Recommended approach documented; implementation pending |
| SchemaStore | Deferred; disabled |
| Dedicated indentation policy | Not established; assess whether one is necessary |
| Standalone YAML linter | Deferred; no tool approved or installed |
| Separate diagnostics for each YAML dialect | Not yet tested |
| Helm template support | Excluded |
| Chezmoi YAML template support | Excluded |

These items do not block the current supported YAML baseline.

### 7.4 Interactive checks

The following checks have been completed:

1. Open representative YAML files and confirm their filetypes.
2. Confirm `yamlls` attachment for all five supported filetypes.
3. Inspect standard YAML highlighting.
4. Inspect diagnostics on valid and invalid standard YAML examples.
5. Exercise completion in key and value positions.
6. Test LSP hover.
7. Confirm Prettier formatter discovery for each supported filetype.
8. Invoke `:Format` for each supported filetype and confirm successful execution.

All listed checks passed.

Schema behavior, dedicated indentation policy, and separate diagnostic tests for every dialect remain outside the completed validation scope.

## 8. Implementation boundaries

YAML support preserves the existing project architecture.

| Responsibility | Location |
|---|---|
| Language-specific configuration | `lua/langs/data.lua` |
| Shared LSP lifecycle | `lua/config/lsp.lua` |
| Centralized keymaps | `lua/config/keymaps.lua` |
| Formatting integration | `lua/config/format.lua` |
| Formatting preferences | `lua/config/languages.lua` |
| Tree-sitter | Existing Tree-sitter integration |
| External dependencies | Existing dependency-management conventions |
| Project-specific schemas | Individual project repositories |
| Schema associations | YAML modelines or explicit language-server mappings |

Do not add duplicate registries, a second formatter integration, another LSP framework, or a new linting framework.

Do not modify shared configuration solely for YAML when the existing infrastructure already provides the required behavior.

## 9. Implementation gates

YAML is third in the preferred Stage 13 build order, after Lua and Python.

The following YAML filetypes are implemented and validated:

1. Standard YAML
2. Docker Compose
3. Ansible
4. GitLab CI
5. Helm values

Remaining work for optional extensions includes:

1. Implement and validate local JSON Schema associations.
2. Evaluate explicit workspace-level schema mappings.
3. Decide whether SchemaStore provides sufficient additional value.
4. Decide whether a dedicated indentation policy is necessary.
5. Add separate diagnostic tests for additional dialects if required.
6. Review regressions and keep documentation synchronized.

Planning, implementation, or successful headless tests do not independently declare earlier-stage closeout requirements satisfied.

Any extension beyond the current supported YAML baseline requires explicit scope and validation.

## 10. Explicit non-goals

The current implementation does not authorize:

- Treating unsupported YAML-based formats as supported automatically.
- Treating JSON Schema validation as implemented merely because the language server supports it.
- Enabling automatic SchemaStore integration by default.
- Enabling format-on-save by default.
- Introducing new plugins or another LSP, formatting, or linting framework.
- Adding automatic dependency installation during Neovim startup.
- Assuming remote schema catalogues are always available.
- Adding Helm template or chezmoi template support.
- Claiming that every YAML dialect has independently passed diagnostics, completion, and hover tests.

## 11. Decision summary

The YAML implementation uses:

- Neovim's native LSP APIs.
- The maintained `nvim-lspconfig` `yamlls` definition.
- YAML Language Server for diagnostics, completion, and hover.
- Prettier through the existing Conform.nvim integration.
- The existing Tree-sitter integration with explicit YAML parser installation.
- Existing language-pack metadata and shared configuration infrastructure.

All five supported YAML filetypes have passed language-server attachment and Prettier formatting checks. Standard YAML has also passed diagnostics, completion, hover, and visual highlighting checks.

YAML Language Server's built-in JSON Schema capability is available, but schema association and validation remain unimplemented. Project-owned schemas and YAML modelines are the preferred management approach. Explicit workspace associations are available when needed. SchemaStore remains optional and disabled.

A dedicated indentation policy and standalone linting remain deferred. Separate diagnostic tests for every YAML dialect have not yet been completed.

The implementation is located in `lua/langs/data.lua` and shares the data-language architecture with JSON, JSONC, JSON5, jq, and TOML support.

**Status:** YAML baseline implemented and validated across five supported filetypes. Optional capability evaluation remains deferred.
