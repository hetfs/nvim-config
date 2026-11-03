# Language Support Architecture Guide

## 1\. Purpose

This document defines the long-term architecture for language and technology support in the Neovim configuration.

It provides a reference for adding, organizing, discovering, activating, and maintaining language packs as the project grows.

The architecture must accommodate different technology groups, including:

- General-purpose programming languages
- Systems programming languages
- Scripting languages
- Web development technologies
- Data formats and query languages
- Configuration languages
- Markup and document languages
- Infrastructure and automation technologies
- Frameworks and domain-specific languages

The goal is to support a growing technology ecosystem without turning the language registry into a collection of technology-specific configuration or duplicating shared infrastructure.

## 2\. Architectural principles

All future language support should follow these principles.

### 2.1 Independent technology packs

Each technology should have an independent language pack when it has distinct configuration, tooling, or lifecycle requirements.

For example:

- Lua should have its own pack.
- Python should have its own pack.
- HTML should have its own pack.
- CSS should have its own pack.
- TypeScript should have its own pack.
- Rust should have its own pack.
- SQL should have its own pack when introduced.

A technology should not need to share a large configuration module with unrelated technologies simply because they belong to the same category.

### 2.2 Centralized shared infrastructure

Language packs should describe their technology-specific requirements.

Shared infrastructure should remain centralized.

Examples include:

| Infrastructure | Responsibility |
| --- | --- |
| LSP | Language-server configuration and activation |
| Conform | Formatting integration |
| Treesitter | Parser installation and highlighting |
| Diagnostics | Diagnostic presentation and configuration |
| Completion | Completion-engine integration |
| Snippets | Shared snippet infrastructure |
| Debugging | DAP infrastructure |
| Installation | External executable management |
| Validation | Smoke tests and configuration validation |

A language pack should not install or initialize a second copy of shared infrastructure.

### 2.3 Native-first integration

Prefer Neovim's native capabilities before introducing additional plugins.

Examples:

- Native LSP client through `vim.lsp.config()` and `vim.lsp.enable()`.
- Native filetype detection through `vim.filetype.add()`.
- Native process execution through `vim.system()`.
- Native buffer and window APIs.
- Native diagnostics and quickfix integration.

Plugins should solve a clearly identified requirement that native functionality does not adequately cover.

### 2.4 Explicit dependencies

A language pack must not silently install tools or activate unrelated technologies.

Installation, activation, and optional features must have explicit policies.

Approval is not installation.

### 2.5 Incremental growth

New technology support should be introduced when needed.

Do not create empty modules, speculative abstractions, or framework-specific infrastructure before there is a concrete requirement.

## 3\. Technology classification

Technology categories provide an organizational reference. They do not determine whether technologies must share a language pack.

### 3.1 General-purpose programming languages

Examples:

- Lua
- Python
- Java
- C#
- Go
- Ruby
- PHP
- Kotlin
- Swift
- Dart

### 3.2 Systems programming languages

Examples:

- C
- C++
- Rust
- Zig
- Assembly
- Objective-C

These technologies may require additional toolchains, debuggers, build systems, and compiler integrations.

### 3.3 Scripting and automation languages

Examples:

- Bash
- Zsh
- Fish
- PowerShell
- Nushell
- Perl
- Tcl

Support may include shell-specific diagnostics, formatting, linting, execution, and completion.

### 3.4 Web development technologies

**Markup**

- HTML
- XML
- SVG

**Stylesheets**

- CSS
- SCSS
- Sass
- Less

**JavaScript ecosystem**

- JavaScript
- TypeScript
- JSX
- TSX

**Frameworks and component technologies**

- Vue
- Svelte
- Astro
- Angular templates
- Web Components

Each technology should be considered independently when its configuration and tooling justify a separate pack.

### 3.5 Data formats and query technologies

**Structured data**

- JSON
- JSONC
- JSON5
- YAML
- TOML
- XML

**Configuration formats**

- INI
- Properties
- HCL
- Nix

**Tabular data**

- CSV
- TSV

**Query and transformation**

- jq
- yq
- JMESPath

**Schemas and specifications**

- JSON Schema
- CUE
- OpenAPI
- AsyncAPI
- Protocol Buffers

**Data query languages**

- SQL
- GraphQL

These technologies may have different requirements for formatting, validation, schema support, querying, and language servers.

### 3.6 Markup and documentation technologies

Examples:

- Markdown
- MDX
- reStructuredText
- AsciiDoc
- LaTeX
- Typst

### 3.7 Infrastructure and configuration technologies

Examples:

- Dockerfile
- Docker Compose
- Kubernetes manifests
- Helm templates
- Terraform
- Ansible
- Packer
- CloudFormation

These technologies may overlap with configuration formats and scripting languages.

Their classification should reflect their actual editing and tooling requirements.

### 3.8 Domain-specific languages

Examples:

- GraphQL
- Protobuf
- SQL
- Vimscript
- Regex
- WGSL
- GLSL

A domain-specific language should receive an independent pack when its support requires distinct configuration or workflows.

## 4\. Directory architecture

The registry should discover language packs from the root of `lua/langs/`.

Recommended structure:

``` text
lua/
└── langs/
    ├── init.lua
    │
    ├── lua.lua
    ├── python.lua
    ├── rust.lua
    ├── c.lua
    ├── cpp.lua
    │
    ├── bash.lua
    ├── powershell.lua
    │
    ├── html.lua
    ├── css.lua
    ├── javascript.lua
    ├── typescript.lua
    ├── vue.lua
    ├── svelte.lua
    │
    ├── data.lua
    ├── sql.lua
    ├── graphql.lua
    ├── xml.lua
    │
    ├── markdown.lua
    ├── typst.lua
    │
    └── terraform.lua
```

This is an illustrative future structure, not a list of technologies to implement immediately.

### 4.1 Root-level discovery

The current registry discovers Lua files directly under:

``` text
lua/langs/*.lua
```

It excludes `init.lua` and loads the remaining modules as language packs.

Therefore:

- Every independently discoverable pack must have a root-level entry module.
- A technology must not be hidden in a subdirectory if the registry is expected to discover it independently.
- Internal submodules may be used when a pack becomes complex.
- The root-level module remains the public entry point.

For example:

``` text
lua/langs/
├── init.lua
├── rust.lua
└── rust/
    ├── lsp.lua
    ├── formatting.lua
    └── debugging.lua
```

The registry discovers `langs.rust`, not its internal modules.

## 5\. Language pack contract

Every language pack must expose a consistent public interface.

The basic contract is:

``` lua
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

Not every pack needs every metadata field.

Only declare metadata that the technology actually requires.

### 5.1 Metadata responsibilities

| Field | Purpose |
| --- | --- |
| `formatters` | Formatter configuration consumed by shared formatting infrastructure |
| `filetypes` | Technology-specific filetype metadata |
| `parsers` | Treesitter parser names |
| `servers` | Language-server identifiers |
| `executables` | Executable requirements for relevant integrations |

Metadata must follow the conventions enforced by the existing registry.

Avoid adding fields without defining their purpose and consumer.

### 5.2 Private implementation

Technology-specific helpers should remain local to their pack.

Examples:

- LSP configuration.
- Executable checks.
- FileType autocmd registration.
- Buffer-local options.
- Technology-specific commands.
- Specialized workflows.
- Optional integration configuration.

Only expose public functions when another module has a legitimate reason to call them.

### 5.3 Setup function

The `setup()` function is the pack's initialization entry point.

It should:

1. Configure technology-specific settings.
2. Register required autocmds and commands.
3. Configure technology-specific LSP behavior.
4. Activate supported integrations according to the pack's activation policy.
5. Avoid installing external tools.

A pack must fail visibly when its own required configuration is invalid.

Missing optional executables should be handled according to the declared optionality policy rather than causing unrelated configuration failures.

## 6\. Discovery and activation

Discovery and activation are separate architectural responsibilities.

**Discovery** determines which language packs exist.

**Activation** determines which discovered packs should initialize.

The current registry discovers root-level modules and calls each pack's `setup()` function.

This means the current implementation automatically initializes discovered packs. Independent discovery does not yet imply user-controlled activation.

A future registry evolution should distinguish these operations.

The intended model is:

``` text
                 Language registry
                         |
                  Discover packs
                         |
                 Validate contracts
                         |
                 Resolve activation
                         |
              +----------+----------+
              |          |          |
            Lua       Python       Rust
              |          |          |
            setup()    setup()     setup()
```

Activation policy should support:

- Core technologies.
- Optional technologies.
- Explicitly disabled technologies.
- Technology-specific configuration.
- Dependency validation.

Do not implement activation controls until their configuration contract is defined.

The existing registry should remain stable while the architecture is being documented.

## 7\. Shared tooling and dependencies

Independent language packs must not result in duplicated external tools or shared infrastructure.

For example, Prettier can serve several technologies:

- HTML
- CSS
- JavaScript
- TypeScript
- JSON
- YAML
- Markdown

Each pack can declare its formatter metadata while the shared Conform integration resolves the configuration.

Similarly:

- Treesitter remains a shared plugin.
- The LSP client remains native.
- Completion remains centralized.
- Debugging infrastructure remains centralized.
- External tool installation remains managed by the installation system.

### 7.1 Tool ownership

Each external executable should have a clear installation owner and dependency definition.

A shared executable must not be installed independently by every language pack.

The installation manifest should remain the authoritative source for installation metadata.

Language packs should describe integration requirements, not duplicate installation logic.

### 7.2 Optional dependencies

A language pack may support optional tools.

For example, a web technology may support Emmet as an optional integration.

Optional tools must:

- Remain disabled unless explicitly enabled.
- Be checked before activation.
- Not become mandatory dependencies of unrelated packs.
- Be documented with their installation and activation requirements.

## 8\. Data pack evolution

The current `data.lua` supports:

- YAML
- JSON
- TOML
- jq

This is an appropriate starting point.

Future data support may include:

- XML
- CSV and TSV
- JSON Schema
- CUE
- yq
- SQL
- GraphQL
- OpenAPI
- Protocol Buffers
- HCL
- INI

Do not assume that every technology belongs permanently in `data.lua`.

As support grows, evaluate each technology based on:

1. Configuration complexity.
2. Tooling requirements.
3. Independent activation needs.
4. Specialized workflows.
5. Shared dependencies.
6. Maintenance boundaries.

A technology such as jq may eventually deserve its own pack because its query and transformation workflow differs from ordinary structured-document editing.

The data architecture will be reviewed separately. The current `data.lua` should not be refactored merely to anticipate future technologies.

## 9\. Technology pack versus shared infrastructure

The following distinction should guide future implementation decisions.

| Concern | Ownership |
| --- | --- |
| Technology-specific LSP settings | Language pack |
| Technology-specific buffer options | Language pack |
| Technology-specific commands | Language pack |
| Formatter selection metadata | Language pack |
| Formatter plugin setup | Shared infrastructure |
| Treesitter plugin setup | Shared infrastructure |
| LSP client initialization | Shared infrastructure |
| Completion engine | Shared infrastructure |
| External tool installation | Installation system |
| Technology activation policy | Registry and pack configuration |
| Shared diagnostics presentation | Shared infrastructure |

The goal is to avoid two architectural extremes:

- A single enormous module containing every technology.
- Excessive fragmentation where every small configuration detail becomes a separate module.

A module should be separated when it has a clear responsibility and improves maintainability.

## 10\. Adding a new technology

Every new language pack should follow a consistent implementation process.

### Step 1: Classify the technology

Identify its category and determine whether it needs an independent pack.

### Step 2: Define the support scope

Identify the required capabilities:

- Filetype detection.
- Treesitter parser.
- Language server.
- Formatter.
- Linter.
- Completion.
- Snippets.
- Debugging.
- Specialized workflows.

Do not assume every technology requires every capability.

### Step 3: Evaluate dependencies

Identify:

- Required executables.
- Optional executables.
- Shared tools.
- Installation methods.
- Version requirements.

### Step 4: Create the root-level pack

Follow the language pack contract.

### Step 5: Integrate with shared infrastructure

Use existing metadata aggregation and shared integrations.

Do not create duplicate plugin configurations.

### Step 6: Validate independently

Test:

- Module loading.
- Metadata collection.
- Filetype detection.
- Parser availability.
- LSP activation.
- Formatter resolution.
- Executable detection.
- Technology-specific workflows.

### Step 7: Document the technology

Record its support scope, dependencies, installation instructions, activation behavior, and validation results.

## 11\. Architectural constraints

The following rules should remain consistent across the project.

1. Use `vim.pack` for plugin management.
2. Do not introduce Mason.
3. Prefer native Neovim functionality.
4. Keep language packs independently discoverable.
5. Keep shared infrastructure centralized.
6. Do not duplicate shared tool installation.
7. Do not silently activate optional integrations.
8. Do not create speculative technology modules.
9. Keep technology-specific configuration inside its pack.
10. Preserve direct and visible module-loading failures.
11. Validate each technology independently.
12. Avoid changing unrelated language packs when introducing new support.

## 12\. Current implementation versus future architecture

It is important to distinguish the current implementation from the intended future architecture.

| Capability | Current state | Future direction |
| --- | --- | --- |
| Root-level pack discovery | Implemented | Preserve |
| Pack `setup()` contract | Implemented | Preserve |
| Metadata aggregation | Implemented | Extend only when needed |
| Independent technology packs | Partially implemented | Expand |
| User-controlled pack activation | Not implemented by current registry | Design later |
| Shared infrastructure | Implemented for existing integrations | Expand carefully |
| Data pack decomposition | Not implemented | Evaluate separately |
| External tool installation | Separate installation system | Preserve centralized ownership |
| Technology-specific validation | Existing smoke-test infrastructure | Extend per pack |

## 13\. Final architectural direction

The long-term architecture is based on three layers:

**Layer 1: Technology packs**

Each independently supported technology owns its configuration and metadata.

**Layer 2: Language registry**

The registry discovers packs, validates their contracts, aggregates metadata, and eventually manages activation policy.

**Layer 3: Shared infrastructure**

Common integrations such as LSP, formatting, Treesitter, completion, diagnostics, debugging, and installation remain centralized.

``` text
                 Technology packs
                        |
          +-------------+-------------+
          |             |             |
        Lua          Python          Rust
          |             |             |
        HTML           CSS        TypeScript
          |             |             |
        SQL            jq          Markdown
          +-------------+-------------+
                        |
                 Language registry
                        |
             Shared metadata aggregation
                        |
              +---------+---------+
              |         |         |
             LSP    Formatting  Treesitter
              |         |         |
              +---------+---------+
                        |
                 Neovim configuration
```

This architecture allows the project to grow across programming languages, systems languages, scripting languages, web technologies, data formats, infrastructure tools, and domain-specific languages.

The architecture should grow through independently maintained technology packs and reusable shared infrastructure, not through increasingly large category-specific modules.

**Implementation policy:** Establish the architecture now as a reference. Introduce changes only when a concrete technology requires them. Keep the current data pack intact until its future decomposition is deliberately evaluated.
