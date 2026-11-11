# Web Language Support Architecture

## 1. Purpose

This document defines the architecture, organization, activation model,
and shared tooling strategy for web-language support in the Neovim
configuration.

The design follows the project's broader language-support architecture:

- Each language or technology has an independent language pack.
- Shared infrastructure is centralized.
- Language-specific configuration belongs to the relevant pack.
- External tools are installed independently of Neovim startup.
- Native Neovim APIs are preferred.
- Plugins and external tools are introduced only when they provide
    necessary functionality.

The objective is to support web development without introducing a
monolithic configuration module or coupling unrelated technologies.

## 2. Architectural Principles

### 2.1 Independent language packs

Each web technology must be independently discoverable and activatable.

For example:

- HTML can be enabled without CSS.
- CSS can be enabled without HTML.
- JavaScript can be enabled without TypeScript.
- TypeScript can be enabled without JavaScript.

A language pack must not require another pack merely because both
technologies share a language server, formatter, or development tool.

### 2.2 Centralized shared infrastructure

Shared infrastructure belongs outside individual language packs.

Examples include:

- Language Server Protocol configuration.
- Formatter integration.
- Diagnostics.
- Tree-sitter installation and initialization.
- Completion.
- Snippet integration.
- External-tool validation.

Language packs declare their requirements and provide language-specific
configuration. Shared infrastructure handles the common implementation.

### 2.3 No monolithic web pack

Do not introduce a central `web.lua` that initializes HTML, CSS,
JavaScript, TypeScript, and other web technologies.

Each technology must remain independently discoverable through the
existing language-pack registry.

### 2.4 Optional tooling remains optional

Productivity tools must not become mandatory dependencies of unrelated
language packs.

For example, Emmet must remain independently configurable rather than
being automatically installed or activated by HTML and CSS.

## 3. Directory Architecture

The web-language architecture follows the existing root-level
language-pack convention.

``` text
lua/
├── langs/
│   ├── init.lua
│   ├── html.lua
│   ├── css.lua
│   ├── javascript.lua
│   ├── typescript.lua
│   │
│   ├── vue.lua
│   ├── svelte.lua
│   ├── astro.lua
│   ├── xml.lua
│   └── svg.lua
│
├── lsp/
│   └── servers/
│       ├── vtsls.lua
│       └── emmet.lua
│
├── config/
│   ├── languages.lua
│   └── format.lua
│
└── plugins/
    ├── lsp.lua
    └── treesitter.lua
```

The list includes both implemented and potential future packs. A file
should only appear in the actual configuration when its implementation
is introduced.

### Ownership

| Component | Responsibility |
|---|---|
| `langs/*.lua` | Technology-specific configuration and metadata |
| `langs/init.lua` | Pack discovery, activation, and metadata aggregation |
| `lsp/servers/` | Shared language-server and optional productivity-tool integrations |
| `config/languages.lua` | Pack activation, optional-tool activation, and formatting preferences |
| `config/format.lua` | Shared Conform configuration |
| `plugins/lsp.lua` | LSP-related plugin installation |
| `plugins/treesitter.lua` | Shared parser installation and highlighting |

Submodules inside a language pack directory are not automatically
discovered. The root-level pack remains the registry entry point.

## 4. Core Web Language Packs

### 4.1 HTML

**Pack:** `lua/langs/html.lua`

HTML owns:

- HTML language-server configuration.
- HTML formatter metadata.
- HTML Tree-sitter parser metadata.
- HTML-specific language settings.

Shared infrastructure handles server activation, formatting, and parser
installation.

Current implementation decisions:

  Capability              Implementation
  ----------------------- -------------------------------
  Language server         `vscode-html-language-server`
  LSP configuration       Native `vim.lsp.config()`
  LSP activation          Native `vim.lsp.enable()`
  Formatter               Prettier
  Formatter integration   Conform
  Tree-sitter parser      `html`

HTML formatting through Prettier is manually triggered using `:Format`
or the configured formatting keymap.

### 4.2 CSS

**Pack:** `lua/langs/css.lua`

CSS owns:

- CSS language-server configuration.
- CSS formatter metadata.
- CSS Tree-sitter parser metadata.
- CSS-specific validation settings.

Current implementation decisions:

| Capability | Implementation |
|---|---|
| Language server | `vscode-css-language-server` |
| LSP configuration | Native `vim.lsp.config()` |
| LSP activation | Native `vim.lsp.enable()` |
| Formatter | Prettier |
| Formatter integration | Conform |
| Tree-sitter parser | `css` |

The CSS language server supports CSS, SCSS, and Less filetypes.

These filetypes must be considered when configuring server attachment.
They do not require separate CSS language packs unless a future
architectural decision establishes a need for them.

### 4.3 JavaScript

**Pack:** `lua/langs/javascript.lua`

JavaScript owns:

- JavaScript formatter metadata.
- JavaScript Tree-sitter parser metadata.
- JavaScript-specific language configuration.

Current implementation decisions:

| Capability | Implementation |
|---|---|
| Language server | `vtsls` |
| Formatter | Prettier |
| Formatter integration | Conform |
| Tree-sitter parser | `javascript` |

The JavaScript pack supports:

- JavaScript (`.js`)
- JavaScript React/JSX (`.jsx`)

The shared vtsls integration handles server configuration and
activation.

### 4.4 TypeScript

**Pack:** `lua/langs/typescript.lua`

TypeScript owns:

- TypeScript formatter metadata.
- TypeScript and TSX Tree-sitter parser metadata.
- TypeScript-specific language configuration.

Current implementation decisions:

| Capability | Implementation |
|---|---|
| Language server | Shared vtsls integration |
| Formatter | Prettier |
| Formatter integration | Conform |
| TypeScript parser | `typescript` |
| TSX parser | `tsx` |

Supported filetypes:

- TypeScript (`.ts`)
- TypeScript React/TSX (`.tsx`)

TypeScript and JavaScript share vtsls, but neither language pack depends
on the other.

## 5. Shared Language Server Architecture

### 5.1 The vtsls integration

JavaScript and TypeScript use the same language server: vtsls.

The shared integration belongs in:

``` text
lua/lsp/servers/vtsls.lua
```

This module owns:

- Server configuration.
- Enabled-pack inspection.
- Filetype aggregation.
- Server activation.
- Prevention of duplicate configuration.

The language packs invoke the shared integration independently.

``` lua
function M.setup()
  require("lsp.servers.vtsls").setup()
end
```

The shared integration determines which filetypes to register by
inspecting:

``` lua
require("config.languages").packs
```

### 5.2 Activation behavior

The expected activation contract is:

| JavaScript | TypeScript | vtsls filetypes |
|---|---|---|
| Enabled | Disabled | JavaScript and JSX |
| Disabled | Enabled | TypeScript and TSX |
| Enabled | Enabled | JavaScript, JSX, TypeScript, and TSX |
| Disabled | Disabled | No vtsls activation |

This design preserves independent language-pack activation without
duplicating server definitions.

### 5.3 Server ownership

Do not declare duplicate `vtsls` server metadata in both language packs.

The shared integration owns the server configuration. Individual packs
own their language-specific formatter and parser metadata.

## 6. Formatting Architecture

### 6.1 Prettier

Prettier is the shared formatter for the supported web-language packs.

It is integrated through Conform.

| Language | Filetype | Formatter |
|---|---|---|
| HTML | `html` | Prettier |
| CSS | `css` | Prettier |
| JavaScript | `javascript` | Prettier |
| TypeScript | `typescript` | Prettier |
| TypeScript React | `typescriptreact` | Prettier |

The formatter is declared by each language pack rather than configured
independently in multiple places.

### 6.2 Formatting policy

The project uses manual formatting.

Supported commands:

``` vim
:Format
```

The configured formatting keymap is also available.

Current policy:

- Format-on-save is disabled by default.
- LSP formatting fallback is disabled.
- Conform owns formatter selection and execution.
- Language servers provide language intelligence rather than replacing
    the configured formatter.

### 6.3 Formatters and linters are different responsibilities

Do not classify ESLint or Stylelint as formatters.

| Tool | Responsibility |
|---|---|
| Prettier | Formatting |
| ESLint | JavaScript and TypeScript linting |
| Stylelint | CSS and related stylesheet linting |

Linting and formatting should remain separate workflows, even when both
operate on the same filetype.

## 7. Tree-sitter Architecture

Tree-sitter configuration is centralized in:

``` text
lua/plugins/treesitter.lua
```

Each language pack declares its parser metadata.

Examples:

``` lua
parser_by_filetype = {
  html = "html",
}
```

``` lua
parser_by_filetype = {
  css = "css",
}
```

``` lua
parser_by_filetype = {
  javascript = "javascript",
}
```

``` lua
parser_by_filetype = {
  typescript = "typescript",
  typescriptreact = "tsx",
}
```

The shared Tree-sitter module:

1. Collects parser metadata from enabled packs.
2. Determines the parser associated with the current filetype.
3. Installs missing parsers when needed.
4. Starts Tree-sitter highlighting when the parser is available.

Language packs must not implement their own duplicate
parser-installation workflows.

## 8. Optional Web Technologies

The architecture must support additional web technologies without
coupling them to the core packs.

Potential independent packs include:

| Technology | Proposed pack | Notes |
|---|---|---|
| Vue | `vue.lua` | Vue single-file components |
| Svelte | `svelte.lua` | Svelte components |
| Astro | `astro.lua` | Astro components |
| XML | `xml.lua` | XML documents |
| SVG | `svg.lua` | SVG documents |

These are architectural extension points, not claims that their packs
are already implemented.

Each future pack must independently define:

- Supported filetypes.
- Language-server requirements.
- Formatter requirements.
- Tree-sitter parser metadata.
- Language-specific configuration.
- External executable requirements.

Shared tools may be reused where appropriate.

## 9. Emmet Integration

Emmet is an optional productivity integration.

It must remain independent of the HTML and CSS language packs.

### Design requirements

- Do not make Emmet a required HTML dependency.
- Do not make Emmet a required CSS dependency.
- Do not install Emmet automatically when either pack is enabled.
- Allow independent activation and configuration.
- Reuse shared LSP infrastructure where appropriate.

Emmet provides abbreviation completion and markup authoring assistance.
It does not replace HTML or CSS language servers, formatters, or
Tree-sitter parsers.

### Implementation

Emmet is implemented as an optional shared LSP integration.

| Concern | Implementation |
|---|---|
| npm package | `@olrtg/emmet-language-server` |
| Executable | `emmet-language-server` |
| Installation | Global npm installation, outside Neovim startup |
| LSP configuration name | `emmet_ls` |
| Configuration module | `lua/lsp/servers/emmet.lua` |
| LSP configuration API | Native `vim.lsp.config()` |
| LSP activation API | Native `vim.lsp.enable()` |
| Transport | `--stdio` |
| Root marker | `.git` |
| Completion trigger | Manual native omnifunc completion with `<C-x><C-o>` |

The `emmet_ls` configuration name reuses the server definition supplied
by `nvim-lspconfig`. That upstream definition targets the different
`aca/emmet-ls` executable, so the local configuration explicitly
overrides `cmd` with `emmet-language-server --stdio`. The third-party
definition is not modified.

The integration is controlled independently through
`config.languages.tools.emmet`. It checks that the setting is explicitly
`true` and that the executable is available before configuring and
enabling the server.

The configured filetypes are:

- HTML (`html`)
- CSS (`css`)
- SCSS (`scss`)
- JavaScript React/JSX (`javascriptreact`)
- TypeScript React/TSX (`typescriptreact`)

Emmet is initialized directly from the root `init.lua`, after
`require("config.lsp")` and before `require("langs").setup()`. This
keeps it independent of language-pack activation.

The integration uses LSP completion items and snippet support.
Completion is manually triggered with `<C-x><C-o>`; automatic expansion
is not enabled.

Emmet can attach alongside the HTML or CSS language server in the same
buffer. It does not require either language pack to install or activate
it.

## 10. Language Activation

Language packs and optional shared tools are configured through:

``` lua
lua/config/languages.lua
```

Example:

``` lua
return {
  packs = {
    html = true,
    css = true,
    javascript = true,
    typescript = true,
  },

  tools = {
    emmet = true,
  },

  formatters = {
    preferred = {},
    stop_after_first = {},
    formatters_only = {},
  },

  format_on_save = {
    enabled = false,
    timeout_ms = 500,
  },
}
```

Only explicitly enabled packs contribute metadata and run their setup
functions.

Disabling a language pack does not uninstall its external tools,
parsers, or plugins.

Activation controls Neovim configuration, not external software
installation.

## 11. External Tool Installation

External tools are installed separately from Neovim startup.

The language configuration must not silently install:

- Language servers.
- Formatters.
- Linters.
- Framework tooling.
- Tree-sitter dependencies.

Installation and validation belong to the project's external-tool
management workflow.

This preserves the project principle:

**Approval is not installation.**

Tool availability should be checked explicitly before enabling dependent
functionality.

## 12. Validation Strategy

Every language pack must be validated independently before being marked
complete.

### 12.1 Registry validation

Verify:

- Pack discovery.
- Activation behavior.
- Parser metadata.
- Formatter metadata.
- Duplicate metadata detection.

### 12.2 Filetype validation

Verify that representative files receive the expected filetypes.

### 12.3 Tree-sitter validation

Verify:

- Parser availability.
- Parser installation where necessary.
- Successful parser initialization.
- Syntax highlighting.

### 12.4 LSP validation

Where a language server is configured, verify:

- Executable availability.
- Server activation.
- Client initialization.
- Correct buffer attachment.
- Diagnostics.
- Language-specific capabilities.

Use Neovim's native LSP client inspection:

``` lua
vim.print(vim.lsp.get_clients({ bufnr = 0 }))
```

### 12.5 Formatting validation

Verify:

- Formatter availability.
- Correct formatter selection.
- Successful manual formatting.
- Correct output.

### 12.6 Optional project dependencies

Framework-specific tests must use an appropriate project environment.

For example, TSX validation requires the relevant JSX type declarations
when testing React components.

A missing project dependency must not be mistaken for a broken Neovim
language pack.

### 12.7 Emmet validation

Verify the optional integration independently of language-pack
activation.

The Emmet validation record includes:

- Global npm package installation.
- Executable discovery through `vim.fn.executable()`.
- Native LSP configuration registration.
- Correct `emmet-language-server --stdio` command override.
- Explicit `tools.emmet` activation.
- Startup initialization from the root `init.lua`.
- Emmet client initialization and buffer attachment.
- Coexistence with the HTML language server.
- Manual completion through `<C-x><C-o>`.

Test abbreviation completion in every configured filetype:

| Filetype | Validation abbreviation | Result |
|---|---|---|
| HTML | `ul>li.item$*3` | Passed |
| CSS | `m10` | Passed |
| SCSS | `m10` | Passed |
| JSX | `ul>li.item$*3` | Passed |
| TSX | `ul>li.item$*3` | Passed |

Do not mark Emmet complete based only on configuration registration or
client attachment. Completion must be exercised in each configured
filetype.

## 13. Implementation Status

The following status reflects the current project validation record.

| Technology | Status |
|---|---|
| HTML | Implemented and validated |
| CSS | Implemented and validated |
| JavaScript | Implemented and validated |
| TypeScript | Implemented and validated |
| Vue | Planned |
| Svelte | Planned |
| Astro | Planned |
| XML | Planned |
| SVG | Planned |
| Emmet | Optional; implemented and validated for HTML, CSS, SCSS, JSX, and TSX |

The shared vtsls integration has been validated with JavaScript and
TypeScript enabled together.

The optional Emmet integration has been validated with manual completion
in all five configured filetypes: HTML, CSS, SCSS, JSX, and TSX.

## 14. Architectural Constraints

The following rules govern future web-language development:

1. Do not create a monolithic `web.lua`.
2. Keep HTML, CSS, JavaScript, and TypeScript independently
    activatable.
3. Do not introduce dependencies between independent language packs
    without an explicit architectural reason.
4. Keep shared LSP configuration outside language packs.
5. Keep shared formatter infrastructure centralized.
6. Keep Tree-sitter installation centralized.
7. Do not classify linters as formatters.
8. Keep Emmet optional and independently configurable through
    `tools.emmet`.
9. Do not install external tools during Neovim startup.
10. Do not duplicate shared server configuration across language packs.
11. Keep optional shared tools outside language-pack activation.
12. Validate each pack and optional integration before declaring it
    complete.
13. Distinguish implemented features from planned extensions.

## 15. Summary

The web-language architecture uses independent language packs supported
by centralized infrastructure.

HTML, CSS, JavaScript, and TypeScript each own their language-specific
configuration. Shared services such as vtsls, Conform, and Tree-sitter
remain centralized.

Emmet is an implemented optional shared integration. Its activation is
controlled through `config.languages.tools.emmet`, and its native LSP
configuration is initialized independently of language packs. Manual
completion has been validated in HTML, CSS, SCSS, JSX, and TSX.

Additional technologies can be introduced without restructuring the
existing architecture.

The guiding principle is:

**Independent language packs. Shared infrastructure. Minimal
dependencies. Explicit activation.**
