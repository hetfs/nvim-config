# Web Technology Support Architecture

## 1. Purpose

This document defines the architecture for supporting web development technologies in the Neovim configuration.

It establishes a consistent approach to organizing, discovering, configuring, activating, and maintaining web technology packs.

The architecture must accommodate the evolution of the web ecosystem, including markup, stylesheets, programming languages, component frameworks, template engines, web tooling, and related technologies.

The goal is to support each technology independently while keeping shared infrastructure centralized.

This document is an architectural reference. It does not require immediate implementation of every technology listed.

## 2. Architectural principles

### 2.1 Independent technology packs

Each web technology should have its own independently discoverable language pack when it has distinct configuration, tooling, or activation requirements.

Examples:

- HTML
- CSS
- JavaScript
- TypeScript
- Vue
- Svelte
- Astro

A technology should not depend on a large `web.lua` module to be discovered or configured.

### 2.2 Centralized shared infrastructure

Technology packs should own their technology-specific configuration.

Shared infrastructure should remain centralized.

Examples:

| Infrastructure | Responsibility |
|---|---|
| LSP | Native language-server client and shared configuration |
| Conform | Formatter integration |
| Treesitter | Parser installation and highlighting |
| Completion | Shared completion engine |
| Diagnostics | Diagnostic presentation |
| Snippets | Shared snippet infrastructure |
| Installation | External executable management |
| Validation | Smoke tests and configuration validation |

A technology pack must not create a second instance of shared infrastructure.

### 2.3 Native-first integration

Prefer Neovim's native capabilities before introducing additional plugins.

Examples:

- Native LSP client through `vim.lsp.config()` and `vim.lsp.enable()`.
- Native filetype detection through `vim.filetype.add()`.
- Native buffer and window APIs.
- Native process execution through `vim.system()`.
- Native diagnostics and quickfix integration.

Introduce plugins only when they provide a clearly justified capability.

### 2.4 Independent activation

Supporting one web technology must not automatically activate every related technology.

For example:

- HTML support must not require Vue.
- JavaScript support must not require TypeScript.
- CSS support must not require Sass.
- TypeScript support must not require Angular.
- Supporting a framework must not silently install its entire toolchain.

Each pack should have an explicit activation and dependency policy.

### 2.5 Incremental growth

Implement technologies when there is a concrete requirement.

Do not create empty packs or speculative framework integrations.

## 3. Web technology classification

The following categories provide an organizational reference.

They do not determine which technologies must share a pack.

### 3.1 Markup technologies

Markup technologies describe document structure and content.

| Technology | Description |
|---|---|
| HTML | Standard web document markup |
| XML | Extensible markup language |
| SVG | Scalable vector graphics markup |
| XHTML | XML-based HTML |
| Web Components | Browser-native component technologies |

HTML should be implemented first in the current web-support baseline.

XML and SVG can be evaluated independently when their tooling and configuration requirements are established.

### 3.2 Stylesheet technologies

Stylesheet technologies define presentation and layout.

| Technology | Description |
|---|---|
| CSS | Standard web styling language |
| SCSS | CSS-compatible Sass syntax |
| Sass | Stylesheet language |
| Less | Dynamic stylesheet language |
| Stylus | Expressive stylesheet language |

CSS should be implemented as an independent pack.

Preprocessors should receive separate packs when their language-server, formatter, parser, or tooling requirements justify independent configuration.

### 3.3 JavaScript ecosystem

The JavaScript ecosystem includes programming languages and syntax extensions.

| Technology | Description |
|---|---|
| JavaScript | Web programming language |
| TypeScript | Typed JavaScript superset |
| JSX | JavaScript XML syntax extension |
| TSX | TypeScript XML syntax extension |

JavaScript and TypeScript should have independent packs.

JSX and TSX may initially be supported through their corresponding JavaScript and TypeScript integrations when separate configuration is unnecessary.

Their ownership and filetype handling must remain explicit.

### 3.4 Component frameworks

Frameworks and component technologies may introduce specialized syntax, language servers, formatters, and project tooling.

Examples:

| Technology | Description |
|---|---|
| Vue | Component-based frontend framework |
| Svelte | Component framework and compiler |
| Astro | Content-focused web framework |
| Angular | Frontend framework with component templates |
| React | Component-based UI library |
| SolidJS | Reactive UI library |
| Lit | Web Components library |

Each framework should be evaluated independently.

Framework support must not become a mandatory dependency of its underlying language packs.

For example, React support should not require a separate JavaScript language pack if the existing JavaScript integration already provides the required capabilities.

A separate framework pack is justified when it contributes distinct language tooling or configuration.

### 3.5 Template technologies

Template engines combine markup with application data or programming-language expressions.

Examples:

- EJS
- Pug
- Handlebars
- Nunjucks
- Liquid
- Twig
- Blade
- ERB
- Jinja

Some template technologies belong to backend programming ecosystems.

Their placement should reflect their actual language tooling and ownership rather than assuming that every template engine belongs to the web category.

### 3.6 Web backend technologies

Web backend support may include:

- Node.js
- Deno
- Bun
- PHP
- Ruby
- Go
- Java
- C#

These are programming-language or runtime concerns rather than necessarily separate web technologies.

Their language packs should remain independently organized according to the general language-support architecture.

Web frameworks can integrate with those packs where required.

### 3.7 Web tooling and specifications

The web ecosystem also includes tools and specification languages.

Examples:

| Area | Technologies |
|---|---|
| Linting | ESLint, Stylelint |
| Formatting | Prettier |
| Type checking | TypeScript compiler |
| API specifications | OpenAPI, AsyncAPI |
| API query language | GraphQL |
| Package management | npm, pnpm, Yarn, Bun |
| Build tooling | Vite, Webpack, esbuild |
| Browser testing | Playwright, Cypress |
| Component documentation | Storybook |

These tools do not automatically require independent language packs.

A pack should be introduced only when a technology has a meaningful language-level configuration or activation responsibility.

Shared development tools should remain managed through their appropriate centralized infrastructure.

## 4. Directory architecture

The language registry discovers root-level Lua modules under:

```text
lua/langs/*.lua
```

Every independently discoverable web technology must therefore have a root-level entry module.

Recommended future structure:

```text
lua/
└── langs/
    ├── init.lua
    │
    ├── html.lua
    ├── css.lua
    ├── scss.lua
    ├── sass.lua
    ├── less.lua
    │
    ├── javascript.lua
    ├── typescript.lua
    │
    ├── vue.lua
    ├── svelte.lua
    ├── astro.lua
    ├── angular.lua
    │
    ├── xml.lua
    ├── svg.lua
    │
    └── ...
```

This is a possible future structure, not an implementation checklist.

### 4.1 Independent entry modules

Each technology should expose its own root-level module.

For example:

```text
lua/langs/
├── init.lua
├── html.lua
├── css.lua
├── javascript.lua
└── typescript.lua
```

The registry discovers these modules independently.

Do not introduce a parent `web.lua` module that owns or initializes all web technologies.

### 4.2 Internal submodules

A technology pack may use internal modules when its implementation becomes complex.

For example:

```text
lua/langs/
├── html.lua
├── html/
│   ├── lsp.lua
│   ├── formatting.lua
│   └── options.lua
│
├── typescript.lua
└── typescript/
    ├── lsp.lua
    ├── formatting.lua
    └── tooling.lua
```

The root-level module remains the public entry point.

The registry discovers `langs.html` and `langs.typescript`, not their internal modules.

Do not split a small technology pack prematurely.

## 5. Language pack contract

Every independently supported web technology must follow the existing language-pack contract.

Example:

```lua
local M = {
  formatters = {},
  filetypes = {},
  parsers = {},
  servers = {},
  executables = {},
}

function M.setup()
  -- Technology-specific initialization.
end

return M
```

Only include metadata fields required by the technology.

### 5.1 Metadata responsibilities

| Field | Responsibility |
|---|---|
| `formatters` | Formatter metadata consumed by shared formatting infrastructure |
| `filetypes` | Filetype metadata |
| `parsers` | Treesitter parser names |
| `servers` | Language-server identifiers |
| `executables` | Required executable metadata |

The metadata structure must remain compatible with the existing registry.

Do not introduce new metadata fields without defining their consumers.

### 5.2 Technology-specific configuration

Each pack owns its configuration.

Examples include:

- Language-server settings.
- Buffer-local options.
- FileType autocmds.
- Technology-specific commands.
- Formatter selection.
- Executable checks.
- Framework-specific settings.
- Optional integrations.

Avoid placing technology-specific behavior in unrelated shared configuration modules.

### 5.3 Setup function

Each pack exposes one public `setup()` function.

It should initialize the technology's configuration and integrations.

It must not:

- Install external tools.
- Initialize duplicate shared plugins.
- Configure unrelated technologies.
- Silently enable optional integrations.

## 6. Shared web tooling

Web technologies frequently share external tools.

The architecture must avoid duplicate installation and configuration.

### 6.1 Prettier

Prettier may support multiple technologies:

- HTML
- CSS
- JavaScript
- TypeScript
- JSON
- YAML
- Markdown
- Vue
- Angular templates

Each language pack may declare its formatter metadata.

The shared Conform integration remains responsible for formatter resolution and execution.

Do not configure a separate Conform instance for every technology.

### 6.2 ESLint

ESLint can support JavaScript and TypeScript ecosystems.

Its integration should be evaluated separately from formatting.

Do not treat ESLint as a formatter merely because it can perform certain automatic fixes.

### 6.3 Stylelint

Stylelint can support CSS and related stylesheet technologies.

Its configuration should remain separate from Prettier and the shared formatter infrastructure.

### 6.4 Emmet

Emmet may provide useful completion and expansion functionality for markup and stylesheet workflows.

It should remain optional.

Its activation must be explicit and must not become a mandatory dependency of HTML or CSS support.

### 6.5 Package and build tools

Tools such as npm, pnpm, Yarn, Bun, Vite, and Webpack belong to project tooling.

They should not automatically become language-pack dependencies.

Their installation and integration should be evaluated according to actual workflow requirements.

## 7. Filetype and parser ownership

Each technology pack should declare the filetypes and Treesitter parsers it requires.

Examples:

| Technology | Example filetypes | Parser |
|---|---|---|
| HTML | `html` | `html` |
| CSS | `css` | `css` |
| JavaScript | `javascript`, `javascriptreact` | `javascript` |
| TypeScript | `typescript`, `typescriptreact` | `typescript`, `tsx` |
| Vue | `vue` | `vue` |
| Svelte | `svelte` | `svelte` |
| Astro | `astro` | `astro` |

These are examples and must be verified against the selected parser and tooling versions before implementation.

### 7.1 Filetype detection

Use Neovim's native `vim.filetype.add()` for custom filetype detection.

Technology-specific buffer behavior should be registered by the relevant pack when appropriate.

Avoid adding unrelated framework behavior to a global filetype configuration module.

### 7.2 Parser ownership

The pack declares its parser requirements.

Treesitter installation and configuration remain centralized.

A language pack must not independently initialize another Treesitter plugin instance.

### 7.3 Embedded languages

Web documents may contain multiple languages.

Examples:

- HTML containing CSS and JavaScript.
- Vue files containing HTML, CSS, and JavaScript.
- Svelte files containing markup, styles, and scripts.
- Astro files containing markup, JavaScript, and component expressions.

Embedded-language support must be evaluated separately from ordinary filetype support.

Do not assume that installing the host parser automatically provides complete embedded-language functionality.

## 8. Language-server architecture

Neovim's native LSP client remains responsible for language-server integration.

Use:

- `vim.lsp.config()`
- `vim.lsp.enable()`

The `nvim-lspconfig` plugin may provide server definitions, but it must not become a replacement for the native LSP client architecture.

Each technology pack owns its server-specific configuration.

Shared LSP infrastructure remains centralized.

### 8.1 Server ownership

A technology pack should enable only the servers relevant to that technology.

For example:

- HTML owns HTML language-server configuration.
- CSS owns CSS language-server configuration.
- JavaScript and TypeScript own their respective language-server integration.
- Vue owns Vue-specific language-server configuration.

Server capabilities that span multiple technologies must be evaluated carefully to avoid duplicate clients and conflicting configurations.

### 8.2 Executable validation

Each pack should declare executable requirements where appropriate.

Required and optional executables must be distinguished.

Missing optional tools should not prevent unrelated language packs from loading.

## 9. Dependencies and installation

Language packs describe their integration requirements.

The installation system owns external tool installation.

The installation manifest remains the authoritative source for:

- Executable names.
- Installation methods.
- Packages.
- Versions.
- Dependency requirements.

A shared tool must not be installed independently by every technology pack.

For example, Prettier should have one installation definition even though multiple web technologies use it.

### 9.1 Optional integrations

Optional integrations must be explicitly controlled.

Examples:

- Emmet.
- Framework-specific language servers.
- Additional linting tools.
- Browser testing tools.

Optional integrations must remain disabled unless enabled by configuration.

## 10. Activation and dependency boundaries

The current registry discovers root-level packs and calls their `setup()` functions.

Therefore, independently discoverable does not yet mean independently user-activatable.

A future registry design should distinguish:

1. Pack discovery.
2. Pack validation.
3. Activation policy.
4. Dependency validation.
5. Pack initialization.

The intended future behavior is:

- HTML can be activated independently.
- CSS can be activated independently.
- JavaScript can be activated independently.
- TypeScript can be activated independently.
- Framework packs can be enabled separately.
- Optional tools can be enabled explicitly.

This activation system must be designed without breaking the existing language-pack contract.

## 11. Web support implementation order

The following order is the proposed baseline for implementation.

| Order | Technology | Scope |
|---:|---|---|
| 1 | HTML | Markup, LSP, parser, formatting |
| 2 | CSS | Stylesheets, LSP, parser, formatting |
| 3 | JavaScript | JavaScript language support |
| 4 | TypeScript | TypeScript and TSX support |
| 5 | Vue | Vue component support |
| 6 | Svelte | Svelte component support |
| 7 | Astro | Astro component support |
| 8 | XML | XML editing support |
| 9 | SVG | SVG editing support |

This is an initial implementation order, not a permanent restriction.

Additional technologies should be introduced when project requirements justify them.

Do not implement later technologies as part of an earlier stage.

## 12. Adding a new web technology

Every new technology should follow this process.

### Step 1: Evaluate its scope

Determine whether it requires an independent pack.

Consider:

- Filetypes.
- Parser requirements.
- Language servers.
- Formatters.
- Linters.
- Completion.
- Debugging.
- Framework-specific workflows.

### Step 2: Evaluate shared tooling

Identify existing tools that already support the technology.

Avoid installing duplicate formatters, linters, or language servers.

### Step 3: Define dependencies

Document:

- Required executables.
- Optional executables.
- Installation method.
- Version requirements.
- Shared dependencies.

### Step 4: Create its language pack

Create a root-level module under `lua/langs/`.

Follow the existing language-pack contract.

### Step 5: Integrate shared infrastructure

Use existing LSP, Conform, Treesitter, completion, and diagnostics infrastructure.

Do not create duplicate shared integrations.

### Step 6: Validate independently

Test:

- Module loading.
- Metadata collection.
- Filetype detection.
- Parser availability.
- LSP activation.
- Formatter resolution.
- Executable detection.
- Embedded-language behavior where applicable.
- Technology-specific workflows.

### Step 7: Document the result

Record the supported capabilities, dependencies, activation policy, installation instructions, and validation results.

## 13. Architectural constraints

The following rules apply to all web technology packs.

1. Each independently supported technology must have its own root-level entry module.
2. Do not introduce a central `web.lua` pack that initializes all web technologies.
3. Follow the existing language-pack contract.
4. Keep shared infrastructure centralized.
5. Prefer native Neovim functionality.
6. Use `vim.pack` for plugin management.
7. Do not introduce Mason.
8. Do not duplicate external tool installation.
9. Keep optional integrations disabled unless explicitly enabled.
10. Do not make framework dependencies mandatory for their underlying languages.
11. Avoid speculative modules and premature abstractions.
12. Validate each technology independently.
13. Preserve direct and visible module-loading failures.
14. Avoid modifying unrelated technology packs when adding new support.

## 14. Current implementation versus future architecture

| Capability | Current state | Future direction |
|---|---|---|
| Root-level language-pack discovery | Implemented | Preserve |
| Language-pack `setup()` contract | Implemented | Preserve |
| Metadata aggregation | Implemented | Reuse |
| Independent HTML pack | Proposed | Implement first |
| Independent CSS pack | Planned | Implement after HTML |
| Independent JavaScript pack | Planned | Implement after CSS |
| Independent TypeScript pack | Planned | Implement after JavaScript |
| Framework packs | Future | Add independently |
| Shared web tooling | Partially supported by shared infrastructure | Expand as required |
| User-controlled pack activation | Not implemented by current registry | Design later |
| Centralized external tool installation | Separate installation system | Preserve |

## 15. Final architectural direction

Web support will follow the independent technology-pack architecture.

```text
                 Web technology packs
                           |
          +----------------+----------------+
          |                |                |
         HTML             CSS          JavaScript
          |                |                |
       html.lua          css.lua       javascript.lua
          |                |                |
          +----------------+----------------+
                           |
                       Registry
                           |
                Shared metadata aggregation
                           |
           +---------------+---------------+
           |               |               |
          LSP          Formatting       Treesitter
           |               |               |
           +---------------+---------------+
                           |
                  Neovim configuration
```

Frameworks and additional web technologies can join this architecture independently as the project grows.

The architecture must not assume that web development consists only of HTML, CSS, and JavaScript.

**Implementation policy:** Start with HTML, CSS, JavaScript, and TypeScript according to the agreed implementation order. Add framework and other web technologies independently when their requirements are ready. Keep shared infrastructure centralized and avoid introducing a parent web pack.
