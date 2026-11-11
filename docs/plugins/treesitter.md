# Tree-sitter Configuration

## Overview

The Neovim configuration uses the native Tree-sitter APIs for syntax parsing and highlighting, with `nvim-treesitter` providing parser installation and query management.

The integration follows three principles:

- **Native-first:** Use Neovim's built-in `vim.treesitter` APIs for parser loading and highlighting.
- **Language-pack ownership:** Language packs declare their primary parsers and additional parser dependencies.
- **On-demand installation:** Install missing parsers when a buffer with the corresponding filetype opens.

The implementation lives in:

```text
lua/plugins/treesitter.lua
```

Language-specific parser metadata lives in:

```text
lua/langs/
```

## Responsibilities

The configuration separates plugin management, parser metadata, parser installation, and highlighting.

| Component | Responsibility |
|---|---|
| `vim.pack` | Installs and manages the `nvim-treesitter` plugin. |
| `nvim-treesitter` | Provides parser installation and query management. |
| `lua/langs/` | Declares parser ownership and filetype mappings. |
| `lua/plugins/treesitter.lua` | Coordinates parser validation, installation, and highlighting. |
| `vim.treesitter` | Loads parsers and starts native syntax highlighting. |

The plugin is loaded eagerly. Parser installation remains on demand.

## Plugin initialization

The plugin is registered through Neovim's native package manager:

```lua
vim.pack.add({
  {
    src = "https://github.com/nvim-treesitter/nvim-treesitter",
    name = "nvim-treesitter",
  },
})
```

The parser installation directory is configured explicitly:

```lua
require("nvim-treesitter").setup({
  install_dir = vim.fn.stdpath("data") .. "/site",
})
```

This keeps parser binaries in Neovim's data directory rather than inside the configuration repository.

## Windows build support

Windows parser installation requires suitable archive and compiler tools.

The configuration provides two environment checks before initializing Tree-sitter.

### TAR availability

If Windows is detected and `tar` is unavailable through `PATH`, the configuration checks for the built-in executable:

```text
%WINDIR%\System32\tar.exe
```

When available, its directory is added to the current Neovim process's `PATH`.

### GCC compiler selection

If Windows is detected and `CC` is not already configured, the configuration looks for GCC:

```lua
local gcc = vim.fn.exepath("gcc")

if gcc ~= "" then
  vim.env.CC = gcc
end
```

An existing `CC` setting is preserved.

These checks prepare the environment for parser installation. They do not install system dependencies.

## Language-pack metadata

Tree-sitter metadata belongs to enabled language packs.

The registry exposes two fields consumed by the Tree-sitter integration.

### Primary parser mapping

`parser_by_filetype` maps a Neovim filetype to its primary Tree-sitter parser.

Example:

```lua
parser_by_filetype = {
  markdown = "markdown",
}
```

The primary parser is the parser passed to:

```lua
vim.treesitter.start(buf, parser)
```

Each filetype maps to one primary parser.

### Additional parser dependencies

Some languages require additional parsers for inline syntax or injections.

The `parser_dependencies_by_filetype` field declares these dependencies:

```lua
parser_dependencies_by_filetype = {
  markdown = {
    "markdown_inline",
  },
}
```

Dependencies are installed and made available to Tree-sitter, but they are not started as primary buffer parsers.

### Markdown example

Markdown uses two complementary parsers:

| Parser | Responsibility |
|---|---|
| `markdown` | Primary block-level Markdown parsing. |
| `markdown_inline` | Additional inline Markdown parsing. |

The language pack declares both responsibilities:

```lua
parser_by_filetype = {
  markdown = "markdown",
},

parser_dependencies_by_filetype = {
  markdown = {
    "markdown_inline",
  },
},
```

This distinction preserves the single-primary-parser contract while supporting additional parsing requirements.

### Metadata ownership

Only enabled language packs contribute metadata to the registry.

The Tree-sitter integration collects:

```lua
local langs = require("langs")

local filetype_parsers =
  langs.collect("parser_by_filetype")

local parser_dependencies =
  langs.collect("parser_dependencies_by_filetype")
```

This prevents disabled language packs from contributing parser mappings or dependencies.

The `parsers` inventory field found in some language packs is not currently consumed by `lua/plugins/treesitter.lua`. The active integration uses the two explicit mappings above.

## Metadata validation

The configuration validates registry metadata before creating its `FileType` autocmd.

Primary parser mappings must have:

- Non-empty string filetype keys.
- Non-empty string parser names.

Additional parser dependencies must have:

- Non-empty string filetype keys.
- A corresponding primary parser mapping.
- A non-empty list of parser names.
- Non-empty string entries.
- No duplicate of the filetype's primary parser.

Invalid metadata raises an assertion error during configuration initialization.

This makes configuration errors visible instead of allowing invalid parser declarations to fail silently.

## Parser availability

Before requesting installation, the configuration checks whether a parser is already available.

It searches Neovim's runtime path:

```lua
local files = vim.api.nvim_get_runtime_file(
  "parser/" .. parser .. ".*",
  false
)
```

A parser is considered available only when a matching parser file exists and Neovim can load it:

```lua
local ok = pcall(vim.treesitter.language.add, parser)
```

This avoids unnecessary installation requests and verifies that the parser can actually be loaded.

## On-demand installation

The configuration creates a `FileType` autocmd for the filetypes declared by enabled language packs.

When a matching buffer opens, the callback:

1. Resolves its filetype.
2. Retrieves its primary parser.
3. Ensures the primary parser is available.
4. Requests installation of additional parser dependencies.
5. Starts highlighting with the primary parser.

The primary parser and its dependencies share the same installation mechanism.

### Primary parser installation

The primary parser is requested with highlighting enabled:

```lua
ensure_parser(event.buf, parser, true)
```

When the parser becomes available, the configuration starts highlighting:

```lua
vim.treesitter.start(buf, parser)
```

### Dependency installation

Additional parsers are requested without highlighting:

```lua
for _, dependency in ipairs(parser_dependencies[filetype] or {}) do
  ensure_parser(event.buf, dependency, false)
end
```

This installs the dependency without starting it as the buffer's primary parser.

## Asynchronous installation tracking

Parser installation runs asynchronously.

The configuration maintains a `pending` table keyed by parser name:

```lua
local pending = {}
```

Each entry tracks:

- Buffers waiting for the parser.
- Whether each buffer requires primary highlighting.
- The number of availability checks performed.

This prevents duplicate installation requests when multiple buffers require the same parser.

### Shared installation requests

When an installation is already pending, subsequent requests reuse its state.

A primary-parser request takes precedence over a dependency-only request for the same buffer.

This allows one parser installation to satisfy multiple consumers without creating duplicate installation jobs.

### Installation polling

After requesting installation, the configuration periodically checks parser availability.

The retry interval is 500 milliseconds.

The maximum number of attempts is 600, giving an installation window of approximately five minutes.

When the parser becomes available:

1. Its pending state is cleared.
2. Waiting buffers are examined.
3. Highlighting is started only for buffers that requested it.

If installation does not complete within the retry window, the configuration clears the pending state and displays a warning.

### Error handling

The implementation uses protected calls around parser installation and highlighting.

Failures produce notifications containing the parser name and error details.

This covers:

- Installation request failures.
- Parser installation timeouts.
- Highlighting startup failures.

## Runtime lifecycle

The complete parser lifecycle is:

```text
Neovim startup
      |
      v
Register nvim-treesitter with vim.pack
      |
      v
Configure parser installation directory
      |
      v
Prepare Windows build environment
      |
      v
Collect enabled language-pack metadata
      |
      v
Validate parser mappings and dependencies
      |
      v
Register FileType autocmd
      |
      v
A supported buffer opens
      |
      v
Resolve primary parser and dependencies
      |
      +----------------------+
      |                      |
      v                      v
Primary parser         Dependency parser
      |                      |
      v                      v
Check availability     Check availability
      |                      |
      v                      v
Install if missing     Install if missing
      |                      |
      v                      v
Wait for availability  Wait for availability
      |                      |
      v                      v
Start highlighting     Do not start highlighting
      |                      |
      +----------+-----------+
                 |
                 v
             Complete
```

## Design decisions

### Why native Tree-sitter APIs?

Neovim provides native parser loading and highlighting APIs.

Using `vim.treesitter.language.add()` and `vim.treesitter.start()` keeps parser activation independent of plugin-specific highlighting abstractions.

### Why use `nvim-treesitter`?

The plugin provides parser installation and query management.

It complements Neovim's native Tree-sitter runtime rather than replacing it.

### Why install parsers on demand?

Installing every parser during startup would introduce unnecessary work and make startup dependent on parser availability.

On-demand installation limits parser requests to filetypes that are actually opened.

### Why separate primary parsers and dependencies?

Not every parser required by a language should be started as the primary parser for its buffer.

Separate metadata prevents additional parsers from accidentally replacing or duplicating the primary highlighting configuration.

### Why share installation tracking?

Primary parsers and dependencies use the same installation lifecycle.

A shared tracker avoids duplicated installation requests and keeps retry, timeout, and error-handling behavior consistent.

## Verification

The configuration should be validated at both the Lua and runtime levels.

### Syntax validation

Run:

```powershell
nvim --headless -l scripts/check-syntax.lua
```

This verifies that the Lua configuration files parse successfully.

### Smoke tests

Run:

```powershell
nvim --headless -l scripts/smoke.lua
```

This verifies the existing configuration smoke-test suites.

### Markdown parser verification

Open a Markdown buffer and verify that:

- Its filetype is `markdown`.
- The `markdown` parser is available.
- The `markdown_inline` parser is available.
- The primary highlighting parser is `markdown`.
- The dependency parser is not independently started as the primary parser.

Parser availability can be checked with:

```lua
for _, parser in ipairs({
  "markdown",
  "markdown_inline",
}) do
  local files = vim.api.nvim_get_runtime_file(
    "parser/" .. parser .. ".*",
    false
  )

  local ok, err = pcall(vim.treesitter.language.add, parser)

  print(parser .. ":")
  print("  Parser files: " .. #files)
  print("  Loadable: " .. tostring(ok))

  if not ok then
    print("  Error: " .. tostring(err))
  end
end
```

A successful syntax check alone does not prove parser installation or runtime highlighting. Both should be verified independently.

## Scope and boundaries

The Tree-sitter configuration owns parser installation, parser availability checks, and syntax highlighting activation.

It does not own:

- Language-server configuration or activation.
- Code formatting.
- Markdown linting.
- Markdown table-of-contents generation.
- System dependency installation.
- Language-pack discovery and activation.

Those responsibilities remain with their respective configuration modules.

## Final module ownership

```text
lua/
├── langs/
│   ├── init.lua
│   ├── markdown.lua
│   └── ...
└── plugins/
    └── treesitter.lua
```

`lua/langs/` declares language-specific requirements.

`lua/plugins/treesitter.lua` provides the shared parser installation and highlighting infrastructure.

This separation allows new language packs to declare parser requirements without adding language-specific installation logic to the shared Tree-sitter module.
