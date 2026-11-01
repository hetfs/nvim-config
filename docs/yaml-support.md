## 3.2 Filetype detection

The implementation supports five YAML-related Neovim filetypes:

| Format | Neovim filetype |
|---|---|
| Standard YAML | `yaml` |
| Docker Compose | `yaml.docker-compose` |
| Ansible | `yaml.ansible` |
| GitLab CI | `yaml.gitlab` |
| Helm values | `yaml.helm-values` |

The language pack declares all five filetypes in the `yamlls` configuration.

Custom filetype detection is implemented in:

`lua/config/filetypes.lua`

The module uses Neovim's native `vim.filetype.add()` API to register the additional YAML filetypes. It is loaded directly from the root `init.lua` alongside the other configuration modules.

This registration ensures that Neovim recognizes the custom filetypes independently of the language-server configuration.

The existing Tree-sitter configuration maps the four additional YAML filetypes to the standard YAML parser.

The following mappings have been verified:

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

**Filetype registration and language-server configuration are separate responsibilities:**

- `lua/config/filetypes.lua` registers custom filetypes with Neovim.
- `lua/langs/data.lua` declares supported filetypes for YAML Language Server.
- The existing Tree-sitter configuration maps custom filetypes to the YAML parser.

All four custom filetypes are now registered successfully.

The following health-check warnings have been resolved:

- Unknown filetype `yaml.docker-compose`.
- Unknown filetype `yaml.ansible`.
- Unknown filetype `yaml.gitlab`.
- Unknown filetype `yaml.helm-values`.

`:checkhealth vim.lsp` no longer reports these unknown-filetype warnings.

The implementation uses Neovim's native filetype-registration API and introduces no additional plugin or external dependency.

## 7.3 Deferred and outstanding work

| Area | Status |
|---|---|
| JSON Schema validation | Available in YAML Language Server; configuration and testing deferred |
| Schema management | Recommended approach documented; implementation pending |
| SchemaStore | Deferred; disabled |
| Dedicated indentation policy | Not established; assess whether one is necessary |
| Standalone YAML linter | Deferred; no tool approved or installed |
| Separate diagnostics for each YAML dialect | Not yet tested |
| Neovim custom filetype registration | Implemented and validated |
| LSP filetype health checks | Passed; four previous warnings resolved |
| Helm template support | Excluded |
| Chezmoi YAML template support | Excluded |

Custom filetype registration is complete. All five supported YAML filetypes have passed language-server attachment checks, and the four additional filetypes resolve to the standard YAML Tree-sitter parser.

The remaining items concern optional capabilities and additional validation. They do not block the current YAML baseline.

## 9. Implementation gates

YAML is third in the preferred Stage 13 build order, after Lua and Python.

The following YAML filetypes are implemented and validated for language-server attachment and formatting:

1. Standard YAML
2. Docker Compose
3. Ansible
4. GitLab CI
5. Helm values

Completed implementation gates:

1. Register the four custom YAML filetypes with Neovim.
2. Confirm filetype detection using representative filenames.
3. Resolve the four custom filetype warnings in `:checkhealth vim.lsp`.
4. Confirm `yamlls` attachment for all five filetypes.
5. Verify Tree-sitter parser resolution for all four additional filetypes.
6. Verify Prettier discovery and formatting for all five filetypes.

Remaining optional work:

1. Implement and validate local JSON Schema associations.
2. Evaluate explicit workspace-level schema mappings.
3. Decide whether SchemaStore provides sufficient additional value.
4. Decide whether a dedicated indentation policy is necessary.
5. Add separate diagnostic tests for additional dialects if required.
6. Review regressions and keep documentation synchronized.

The completed implementation gates establish the YAML baseline. Optional schema, indentation, and additional diagnostic work remain separate extensions.

## 11. Decision summary

The YAML implementation uses:

- Neovim's native LSP APIs.
- The maintained `nvim-lspconfig` `yamlls` definition.
- YAML Language Server for diagnostics, completion, and hover.
- Prettier through the existing Conform.nvim integration.
- The existing Tree-sitter integration with explicit YAML parser installation.
- Neovim's native filetype registration through `lua/config/filetypes.lua`.
- Existing language-pack metadata and shared configuration infrastructure.

All five supported YAML filetypes have passed language-server attachment and Prettier formatting checks. Standard YAML has also passed diagnostics, completion, hover, and visual highlighting checks.

The four additional filetypes resolve to the standard YAML Tree-sitter parser. Their Neovim filetype registration is implemented and validated. The four previous `:checkhealth vim.lsp` unknown-filetype warnings are resolved.

YAML Language Server's built-in JSON Schema capability is available, but schema association and validation remain unimplemented. Project-owned schemas and YAML modelines are the preferred management approach. Explicit workspace associations are available when needed. SchemaStore remains optional and disabled.

A dedicated indentation policy and standalone linting remain deferred. Separate diagnostic tests for every YAML dialect have not yet been completed.

The implementation is located in `lua/langs/data.lua` and shares the data-language architecture with JSON, JSONC, JSON5, jq, and TOML support. Custom filetype detection is maintained separately in `lua/config/filetypes.lua`.

**Status:** YAML baseline implemented and interactively validated across five supported filetypes. Custom filetype registration, LSP attachment, formatter resolution, and Tree-sitter parser mappings are validated. Four previous filetype health-check warnings are resolved. Optional capability evaluation remains deferred.
