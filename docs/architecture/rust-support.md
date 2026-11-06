# Rust Support

**Stage:** 13 – Language Packs
**Pack:** `rust`
**Tier:** Core
**Status:** Implementation specification; integration validation pending

This document defines Rust language support for the Neovim configuration. It covers standalone Rust crates and Cargo workspaces, using `rust-analyzer` for language intelligence and `rustfmt` through Conform for formatting.

The implementation follows the project's native-first architecture. It uses Neovim's built-in LSP client, native filetype detection, Treesitter, native inlay hints, and terminal buffers. Existing plugins are reused; no new plugin dependencies are introduced.

## 1. Goals and design principles

- **Native-first:** Use `vim.lsp.config`, `vim.lsp.enable`, native filetype detection, Treesitter, native inlay hints, and terminal buffers.
- **Language intelligence:** Use `rust-analyzer` for completion, hover, navigation, references, rename, code actions, and diagnostics.
- **External formatting:** Use `rustfmt` through Conform. Pass the Rust crate's edition explicitly.
- **Manual formatting:** Expose `:Format` and `<leader>cf`. Format-on-save remains disabled by default.
- **LSP formatting disabled:** `rust-analyzer` must not compete with Conform as the formatting authority.
- **Optional Clippy:** Allow `rust-analyzer` to use Clippy for diagnostics without introducing `nvim-lint`.
- **Workspace awareness:** Use one language-server root per Cargo workspace rather than starting a separate server for every member crate.
- **Edition awareness:** Resolve the crate edition, including workspace-inherited editions.
- **Cross-platform:** Support Windows, Linux, and macOS without shell-specific command construction.
- **No unnecessary dependencies:** Reuse the existing plugin inventory and external-tool management strategy.
- **Testability:** Keep root detection, edition resolution, and configuration checks independent of an installed Rust toolchain.

## 2. Component inventory

| Concern | Component | Type |
|---|---|---|
| Language server | `rust-analyzer` | External tool |
| LSP integration | `nvim-lspconfig` | Existing plugin; server definitions only |
| LSP configuration | `vim.lsp.config` | Neovim native |
| Formatter | `rustfmt` | External tool |
| Formatter integration | Conform | Existing plugin |
| Parser | `rust` | Treesitter |
| Manifest parser | `toml` | Existing data pack |
| Linter | Clippy through rust-analyzer | Optional external tool |
| Build and test commands | Cargo | Rust toolchain |
| Inlay hints | `vim.lsp.inlay_hint` | Neovim native |
| Macro expansion | rust-analyzer extension request | Optional integration |
| Cargo manifest navigation | rust-analyzer extension request | Optional integration |
| External documentation | rust-analyzer extension request | Optional integration |
| Debugging | CodeLLDB | Stage 14 |

`Cargo.toml` and `Cargo.lock` belong to the existing data-language pack. Rust support must not register a second TOML parser or formatter.

## 3. File ownership

The implementation uses the following files:

```text
lua/
├── langs/
│   ├── init.lua
│   └── rust.lua
│
└── config/
    ├── languages.lua
    ├── filetypes.lua
    ├── rust.lua
    └── keymaps.lua

scripts/
└── smoke.lua

docs/
├── languages.md
└── rust-support.md
```

| File | Responsibility |
|---|---|
| `lua/langs/rust.lua` | Rust pack metadata, workspace-root detection, edition detection, and LSP setup |
| `lua/langs/init.lua` | Language-pack registry and setup lifecycle |
| `lua/config/languages.lua` | Conform formatter registration |
| `lua/config/filetypes.lua` | Rust buffer-local settings |
| `lua/config/rust.lua` | Cargo command and optional rust-analyzer commands |
| `lua/config/keymaps.lua` | Centralized Rust keymaps |
| `scripts/smoke.lua` | Offline configuration and helper tests |
| `docs/languages.md` | Core language-pack inventory |
| `docs/rust-support.md` | Rust implementation and validation documentation |

Do not create a second language-pack registry or introduce another plugin-loading mechanism.

## 4. External dependencies

Rust support uses the Rust toolchain installed through `rustup`.

### 4.1 Required components

Install the required components:

```sh
rustup component add rust-analyzer rustfmt rust-src
```

Verify the tools:

```sh
rust-analyzer --version
rustfmt --version
cargo --version
```

The Rust toolchain also supplies `rustc`.

### 4.2 Optional components

Clippy is optional:

```sh
rustup component add clippy
```

Verify:

```sh
cargo clippy --version
```

Clippy is not required for basic Rust language support.

### 4.3 Dependency ownership

The Rust pack declares its external requirements through its language metadata.

| Tool | Requirement | Purpose |
|---|---|---|
| `rust-analyzer` | Required | Language server |
| `rustfmt` | Required | Formatting |
| `cargo` | Required | Build, test, and project management |
| `rustc` | Required through Rust toolchain | Compilation |
| `rust-src` | Required | Rust standard-library source |
| `clippy` | Optional | Additional diagnostics |

Do not install Rust components automatically during Neovim startup.

The existing external dependency installation scripts remain responsible for provisioning tools. Rust support only detects missing executables and reports actionable diagnostics.

Windows, Linux, and macOS should use the same `rustup` component-management workflow.

## 5. Implementation

### 5.1 `lua/langs/rust.lua`

This module owns Rust pack metadata, project-root discovery, edition detection, and language-server configuration.

```lua
local M = {}

M.rust = {
  servers = { "rust_analyzer" },
  parsers = { "rust" },
  filetypes = { "rust" },
  formatters = {
    rust = { "rustfmt" },
  },
  tools = {
    "rust-analyzer",
    "rustfmt",
    "cargo",
  },
}

local function join(...)
  return vim.fs.joinpath(...)
end

local function read_lines(path)
  local ok, lines = pcall(vim.fn.readfile, path)
  return ok and lines or {}
end

local function manifest_has_workspace(dir)
  for _, line in ipairs(read_lines(join(dir, "Cargo.toml"))) do
    if line:match("^%s*%[workspace%]%s*#?") then
      return true
    end
  end

  return false
end

--- Find the nearest crate root.
--- Supports Cargo.toml and rust-project.json.
local function find_crate(path)
  return vim.fs.root(path, {
    "Cargo.toml",
    "rust-project.json",
  })
end

--- Find the nearest Cargo workspace root.
--- Fall back to the nearest crate when no workspace exists.
function M.find_root(path)
  local crate = find_crate(path)

  if not crate then
    return nil
  end

  -- A rust-project.json project without Cargo.toml.
  if vim.fn.filereadable(join(crate, "Cargo.toml")) == 0 then
    return crate
  end

  -- Check the nearest crate first.
  if manifest_has_workspace(crate) then
    return crate
  end

  -- Search parent directories for a workspace manifest.
  for dir in vim.fs.parents(crate) do
    if manifest_has_workspace(dir) then
      return dir
    end
  end

  return crate
end

--- Read the package edition from a Cargo manifest.
--- Returns the edition value or nil.
local function manifest_edition(path)
  local section
  local package_edition
  local workspace_edition
  local inherits_workspace = false

  for _, line in ipairs(read_lines(path)) do
    local header = line:match("^%s*%[([^%]]+)%]")

    if header then
      section = header
    else
      local edition = line:match(
        '^%s*edition%s*=%s*"(%d+)"'
      )

      if edition and section == "package" then
        package_edition = edition
      elseif edition and section == "workspace.package" then
        workspace_edition = edition
      end

      if section == "package"
        and line:match(
          "^%s*edition%s*=%s*{%s*workspace%s*=%s*true%s*}"
        )
      then
        inherits_workspace = true
      end
    end
  end

  if package_edition then
    return package_edition
  end

  if inherits_workspace then
    return nil, true
  end

  return workspace_edition
end

--- Resolve the Rust edition for a source file.
--- Supports explicit package editions and workspace inheritance.
--- Defaults to 2021 when no edition can be resolved.
function M.edition(path)
  local crate = vim.fs.root(path, { "Cargo.toml" })

  if not crate then
    return "2021"
  end

  local edition, inherits = manifest_edition(
    join(crate, "Cargo.toml")
  )

  if edition then
    return edition
  end

  if inherits then
    local root = M.find_root(path)

    if root then
      local workspace_edition = manifest_edition(
        join(root, "Cargo.toml")
      )

      if workspace_edition then
        return workspace_edition
      end
    end
  end

  return "2021"
end

function M.setup()
  vim.lsp.config("rust_analyzer", {
    filetypes = M.rust.filetypes,

    root_dir = function(bufnr, on_dir)
      local path = vim.api.nvim_buf_get_name(bufnr)
      local root = M.find_root(path)

      if root then
        on_dir(root)
      end
    end,

    settings = {
      ["rust-analyzer"] = {
        cargo = {
          allFeatures = false,
          buildScripts = {
            enable = true,
          },
          -- Use a separate rust-analyzer target directory.
          -- This reduces Cargo.lock contention with normal builds.
          targetDir = true,
        },

        procMacro = {
          enable = true,
        },

        check = {
          command = vim.g.config_rust_clippy
              and "clippy"
            or "check",
        },

        diagnostics = {
          enable = true,
        },
      },
    },

    on_attach = function(client, bufnr)
      -- Conform is the authoritative Rust formatter.
      client.server_capabilities.documentFormattingProvider = false
      client.server_capabilities.documentRangeFormattingProvider = false

      if vim.g.config_rust_inlay_hints
        and client:supports_method("textDocument/inlayHint")
      then
        vim.lsp.inlay_hint.enable(true, {
          bufnr = bufnr,
        })
      end
    end,
  })

  vim.lsp.enable("rust_analyzer")
end

return M
```

**Implementation notes**

1. `find_root()` searches for a workspace manifest before falling back to the nearest crate.
2. This prevents separate rust-analyzer roots for ordinary Cargo workspace members.
3. Standalone crates use their own `Cargo.toml`.
4. Projects based on `rust-project.json` can use that file as their project marker.
5. Edition resolution supports explicit package editions and `edition.workspace = true`.
6. The manifest reader is intentionally lightweight. It handles conventional package and workspace edition declarations, not every possible TOML syntax. The data pack's TOML parser remains the authoritative parser for TOML documents.
7. `targetDir = true` uses a separate rust-analyzer target subdirectory. This reduces contention at the cost of duplicated build artifacts.
8. Formatting capabilities are disabled on attach so that Conform remains authoritative.

**Important LSP integration rule**

The Rust-specific `on_attach` replaces an inherited `on_attach` when the server configuration is merged. If Stage 09 defines a shared callback, preserve it explicitly:

```lua
local shared_on_attach = vim.lsp.config["*"].on_attach
```

Then invoke it from the Rust callback if that is how the existing shared LSP architecture is structured.

Do not duplicate shared LSP behavior or silently discard common attachment functionality.

### 5.2 Register Rust in the language registry

The Rust pack must be registered through the existing language registry.

Call:

```lua
require("langs.rust").setup()
```

from the registry's established setup lifecycle.

Keep the registry's existing `setup()` and `collect(field)` contracts. Do not introduce a Rust-specific plugin-loading path.

### 5.3 `lua/config/languages.lua`

Rust formatting belongs in the existing Conform configuration.

Import the Rust pack:

```lua
local rust = require("langs.rust")

local rust_formatters = rust.rust.formatters
```

Merge its formatter metadata into the existing formatter map:

```lua
formatters_by_ft = vim.tbl_extend(
  "force",
  data.formatters,
  web_formatters,
  ts_formatters,
  c_formatters,
  rust_formatters
),
```

Add the Rust formatter configuration to the existing `formatters` table:

```lua
formatters = {
  -- Preserve existing formatter definitions.

  rustfmt = {
    prepend_args = function(_, ctx)
      return {
        "--edition",
        rust.edition(ctx.filename),
      }
    end,
  },
},
```

If the existing configuration already contains a `formatters` table, extend that table rather than defining another one.

#### Why the edition argument matters

`rustfmt` needs to know which Rust edition it should parse.

When formatting through stdin, do not rely on its default edition. An older default can cause valid modern Rust syntax, including asynchronous syntax, to be interpreted incorrectly.

Passing the edition explicitly ensures that formatting uses the edition declared by the crate.

#### Conform argument validation

The configuration assumes Conform's built-in `rustfmt` formatter preserves its required stdout emission argument when `prepend_args` is applied.

Verify the resolved formatter command against the installed Conform version. Do not assume that adding `--edition` guarantees a valid command.

The resolved invocation must:

- Execute `rustfmt`.
- Pass the detected edition.
- Preserve the formatter's stdin/stdout behavior.
- Return formatted source through stdout.
- Avoid modifying the source file directly during Conform formatting.

If the installed formatter definition does not preserve the required arguments, define an explicit formatter command consistent with the installed Conform API.

Validate with:

```vim
:ConformInfo
```

Then format a real Rust source file:

```vim
:Format
```

### 5.4 `lua/config/filetypes.lua`

Rust uses Neovim's built-in `.rs` filetype detection.

No additional filetype registration is required.

Add the following buffer-local configuration to the existing file:

```lua
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup(
    "config_rust",
    { clear = true }
  ),

  pattern = "rust",
  desc = "Rust buffer-local settings",

  callback = function()
    vim.opt_local.shiftwidth = 4
    vim.opt_local.tabstop = 4
    vim.opt_local.softtabstop = 4
    vim.opt_local.expandtab = true

    vim.opt_local.foldmethod = "expr"
    vim.opt_local.foldexpr =
      "v:lua.vim.treesitter.foldexpr()"
  end,
})
```

These are editor defaults. `rustfmt` remains responsible for formatting output.

Do not add a custom `commentstring`. Native Neovim commenting should handle Rust comments.

The Treesitter Rust parser must be included in the Stage 13 parser installation and configuration.

### 5.5 `lua/config/rust.lua`

This module provides:

- `:Cargo` for executing Cargo commands.
- `:RustExpandMacro` for macro expansion.
- `:RustOpenCargoToml` for manifest navigation.
- `:RustOpenDocs` for external documentation.

The Cargo command is the core functionality. The three rust-analyzer extension commands are optional integrations because their request methods and response formats can change between server versions.

```lua
local M = {}

local function notify(msg, level)
  vim.notify(
    "rust: " .. msg,
    level or vim.log.levels.INFO
  )
end

local function client()
  local clients = vim.lsp.get_clients({
    bufnr = 0,
    name = "rust_analyzer",
  })

  if #clients == 0 then
    notify(
      "rust_analyzer is not attached to this buffer",
      vim.log.levels.WARN
    )
    return nil
  end

  return clients[1]
end

--- Run cargo in the project root using a terminal split.
function M.cargo(args)
  if #args == 0 then
    notify(
      "usage: :Cargo <subcommand> [args]",
      vim.log.levels.WARN
    )
    return
  end

  local root = require("langs.rust").find_root(
    vim.api.nvim_buf_get_name(0)
  )

  if not root then
    notify(
      "no Cargo project found above this buffer",
      vim.log.levels.WARN
    )
    return
  end

  if vim.fn.executable("cargo") == 0 then
    notify(
      "cargo not found on PATH",
      vim.log.levels.WARN
    )
    return
  end

  local cmd = { "cargo" }
  vim.list_extend(cmd, args)

  vim.cmd("botright 14new")

  local bufnr = vim.api.nvim_get_current_buf()

  vim.keymap.set("n", "q", "<cmd>close<cr>", {
    buffer = bufnr,
    desc = "Close Cargo terminal",
  })

  local job = vim.fn.jobstart(cmd, {
    cwd = root,
    term = true,
  })

  if job <= 0 then
    vim.cmd("close")
    notify(
      "failed to start cargo process",
      vim.log.levels.ERROR
    )
  end
end

--- Display the macro expansion under the cursor.
function M.expand_macro()
  local c = client()

  if not c then
    return
  end

  local params = vim.lsp.util.make_position_params(
    0,
    c.offset_encoding
  )

  c:request(
    "rust-analyzer/expandMacro",
    params,
    function(err, result)
      if err then
        notify(
          err.message or "macro expansion request failed",
          vim.log.levels.ERROR
        )
        return
      end

      if type(result) ~= "table"
        or type(result.expansion) ~= "string"
      then
        notify(
          "no macro expansion returned",
          vim.log.levels.WARN
        )
        return
      end

      vim.schedule(function()
        vim.cmd("botright vnew")

        local buf = vim.api.nvim_get_current_buf()

        vim.bo[buf].buftype = "nofile"
        vim.bo[buf].bufhidden = "wipe"
        vim.bo[buf].swapfile = false
        vim.bo[buf].filetype = "rust"

        vim.api.nvim_buf_set_lines(
          buf,
          0,
          -1,
          false,
          vim.split(result.expansion, "\n", {
            plain = true,
          })
        )

        vim.keymap.set("n", "q", "<cmd>close<cr>", {
          buffer = buf,
          desc = "Close macro expansion",
        })
      end)
    end,
    0
  )
end

--- Open the Cargo.toml associated with the current document.
function M.open_cargo_toml()
  local c = client()

  if not c then
    return
  end

  local params = {
    textDocument = vim.lsp.util.make_text_document_params(0),
  }

  c:request(
    "experimental/openCargoToml",
    params,
    function(err, result)
      if err then
        notify(
          err.message or "Cargo.toml request failed",
          vim.log.levels.ERROR
        )
        return
      end

      if type(result) ~= "table" then
        notify(
          "no Cargo.toml location returned",
          vim.log.levels.WARN
        )
        return
      end

      vim.schedule(function()
        local ok, open_err = pcall(
          vim.lsp.util.show_document,
          result,
          c.offset_encoding,
          { focus = true }
        )

        if not ok then
          notify(
            tostring(open_err),
            vim.log.levels.ERROR
          )
        end
      end)
    end,
    0
  )
end

--- Open documentation for the symbol under the cursor.
function M.open_docs()
  local c = client()

  if not c then
    return
  end

  local params = vim.lsp.util.make_position_params(
    0,
    c.offset_encoding
  )

  c:request(
    "experimental/externalDocs",
    params,
    function(err, result)
      if err then
        notify(
          err.message or "external documentation request failed",
          vim.log.levels.ERROR
        )
        return
      end

      local url

      if type(result) == "string" then
        url = result
      elseif type(result) == "table" then
        url = result.web or result.local_
      end

      if type(url) ~= "string"
        or not url:match("^https?://")
      then
        notify(
          "no valid external documentation URL returned",
          vim.log.levels.WARN
        )
        return
      end

      local ok, open_err = pcall(vim.ui.open, url)

      if not ok or open_err then
        notify(
          tostring(open_err),
          vim.log.levels.ERROR
        )
      end
    end,
    0
  )
end

local subcommands = {
  "build",
  "check",
  "clippy",
  "doc",
  "fmt",
  "run",
  "test",
  "tree",
  "update",
}

function M.setup()
  vim.api.nvim_create_user_command(
    "Cargo",
    function(cmd)
      M.cargo(cmd.fargs)
    end,
    {
      nargs = "+",

      complete = function(arglead)
        return vim.tbl_filter(function(sub)
          return vim.startswith(sub, arglead)
        end, subcommands)
      end,

      desc = "Run Cargo in the project root",
    }
  )

  vim.api.nvim_create_user_command(
    "RustExpandMacro",
    M.expand_macro,
    {
      desc = "Expand the Rust macro under the cursor",
    }
  )

  vim.api.nvim_create_user_command(
    "RustOpenCargoToml",
    M.open_cargo_toml,
    {
      desc = "Open the owning Cargo.toml",
    }
  )

  vim.api.nvim_create_user_command(
    "RustOpenDocs",
    M.open_docs,
    {
      desc = "Open documentation for the symbol under the cursor",
    }
  )
end

return M
```

#### Load the module

Load the Rust command module through the existing configuration initialization sequence:

```lua
require("config.rust").setup()
```

Keep command registration explicit and consistent with the existing direct module-loading architecture.

#### Usage

```vim
:Cargo build
:Cargo check
:Cargo test
:Cargo run -- --verbose
:Cargo clippy --all-targets
:Cargo fmt
```

The command uses an argument list rather than shell-string construction.

This avoids manual shell quoting and supports Windows PowerShell, Windows Command Prompt, Linux shells, and macOS shells.

The terminal split uses the detected Cargo project root as its working directory.

**Extension compatibility:** The three `Rust*` extension commands must be tested against the installed rust-analyzer. Their request names and response contracts are not guaranteed by the standard LSP protocol. Unsupported requests must produce notifications rather than silently failing.

### 5.6 `lua/config/keymaps.lua`

All user-facing mappings remain centralized.

Add:

```lua
vim.keymap.set(
  "n",
  "<leader>cm",
  "<cmd>RustExpandMacro<cr>",
  {
    desc = "Expand Rust macro",
  }
)
```

Before adding the mapping, inspect the existing `<leader>c` namespace.

Only change the mapping if it conflicts with an established keymap. Preserve the description.

Do not define additional Rust mappings inside `lua/config/rust.lua`.

## 6. Optional configuration

All optional Rust features remain disabled by default.

Configure these values in the existing options module before the language registry initializes.

```lua
vim.g.config_rust_clippy = false
vim.g.config_rust_inlay_hints = false

vim.g.config_format_on_save = false
vim.g.config_lsp_format_fallback = false
```

| Option | Default | Description |
|---|---|---|
| `config_rust_clippy` | `false` | Use Clippy as rust-analyzer's check command |
| `config_rust_inlay_hints` | `false` | Enable native Rust inlay hints |
| `config_format_on_save` | `false` | Enable the existing global format-on-save mechanism |
| `config_lsp_format_fallback` | `false` | Enable the existing global LSP formatting fallback |

### 6.1 Clippy

When enabled:

```lua
vim.g.config_rust_clippy = true
```

The server uses:

```lua
check = {
  command = "clippy",
}
```

This allows rust-analyzer to collect Clippy diagnostics through its normal check mechanism.

Clippy must be installed separately:

```sh
rustup component add clippy
```

Do not introduce `nvim-lint` for this integration.

### 6.2 Native inlay hints

When enabled:

```lua
vim.g.config_rust_inlay_hints = true
```

Neovim enables native inlay hints when rust-analyzer attaches and supports the corresponding LSP method.

The feature remains optional because inlay hints can add visual noise in some workflows.

### 6.3 Formatting policy

Conform remains the authoritative Rust formatter.

The Rust LSP configuration disables formatting capabilities.

Do not introduce an automatic LSP formatting fallback for Rust.

Format-on-save remains disabled until explicitly enabled through the existing global formatting policy.

## 7. Treesitter configuration

The Rust parser belongs in the existing Stage 13 Treesitter parser inventory.

Parser:

```lua
"rust"
```

The implementation uses Treesitter for:

- Syntax highlighting.
- Syntax-aware folding.
- Structural editing support provided by existing native workflows.

Do not install a separate Rust-specific highlighting plugin.

The `toml` parser remains owned by the data-language pack.

## 8. Smoke tests

Rust smoke tests must validate configuration and helper behavior without requiring Rust executables.

Append the following tests to the existing `scripts/smoke.lua` structure.

```lua
-- Rust support
do
  local function check(name, ok, msg)
    if not ok then
      error(
        ("rust: %s failed: %s"):format(
          name,
          msg or ""
        )
      )
    end
  end

  local j = vim.fs.joinpath

  local function write(path, lines)
    vim.fn.mkdir(vim.fs.dirname(path), "p")
    vim.fn.writefile(lines, path)
  end

  -- Filetype detection.
  vim.cmd("filetype on")

  check(
    "Rust filetype",
    vim.filetype.match({
      filename = "main.rs",
    }) == "rust"
  )

  -- Language-server configuration.
  local cfg = vim.lsp.config["rust_analyzer"]

  check(
    "LSP configuration",
    cfg ~= nil,
    "rust_analyzer configuration missing"
  )

  check(
    "LSP root_dir",
    type(cfg.root_dir) == "function"
  )

  check(
    "LSP on_attach",
    type(cfg.on_attach) == "function"
  )

  check(
    "LSP formatting disabled",
    cfg.on_attach ~= nil,
    "Rust attachment callback missing"
  )

  -- Optional defaults.
  check(
    "Clippy disabled by default",
    not vim.g.config_rust_clippy
  )

  check(
    "Inlay hints disabled by default",
    not vim.g.config_rust_inlay_hints
  )

  check(
    "Format-on-save disabled by default",
    not vim.g.config_format_on_save
  )

  check(
    "LSP fallback disabled by default",
    not vim.g.config_lsp_format_fallback
  )

  if not vim.g.config_rust_clippy then
    check(
      "default check command",
      cfg.settings["rust-analyzer"].check.command == "check"
    )
  end

  -- Conform integration.
  local conform_ok, conform = pcall(require, "conform")

  if conform_ok then
    check(
      "Rust formatter registration",
      vim.deep_equal(
        conform.formatters_by_ft.rust,
        { "rustfmt" }
      )
    )

    local formatter =
      require("config.languages").formatters.rustfmt

    check(
      "rustfmt edition callback",
      type(formatter.prepend_args) == "function"
    )
  end

  -- FileType autocmd.
  local autocmds = vim.api.nvim_get_autocmds({
    group = "config_rust",
  })

  check(
    "Rust autocmd",
    #autocmds > 0
  )

  -- User commands.
  for _, cmd in ipairs({
    "Cargo",
    "RustExpandMacro",
    "RustOpenCargoToml",
    "RustOpenDocs",
  }) do
    check(
      "command " .. cmd,
      vim.fn.exists(":" .. cmd) == 2,
      cmd .. " missing"
    )
  end

  -- Centralized keymap.
  local map = vim.fn.maparg(
    "<leader>cm",
    "n",
    false,
    true
  )

  check(
    "Rust keymap description",
    map and map.desc and map.desc ~= ""
  )

  -- Buffer-local options.
  vim.cmd("enew")
  vim.bo.filetype = "rust"

  check(
    "expandtab",
    vim.bo.expandtab == true
  )

  check(
    "shiftwidth",
    vim.bo.shiftwidth == 4
  )

  check(
    "tabstop",
    vim.bo.tabstop == 4
  )

  check(
    "softtabstop",
    vim.bo.softtabstop == 4
  )

  vim.cmd("bwipeout!")

  -- Root and edition detection.
  local rust = require("langs.rust")

  -- Workspace with an inherited member edition.
  local ws = vim.fn.tempname()

  write(
    j(ws, "Cargo.toml"),
    {
      "[workspace]",
      'members = ["crates/foo"]',
      "",
      "[workspace.package]",
      'edition = "2024"',
    }
  )

  write(
    j(ws, "crates", "foo", "Cargo.toml"),
    {
      "[package]",
      'name = "foo"',
      'edition.workspace = true',
    }
  )

  write(
    j(ws, "crates", "foo", "src", "lib.rs"),
    { "" }
  )

  local member_file = j(
    ws,
    "crates",
    "foo",
    "src",
    "lib.rs"
  )

  check(
    "workspace root",
    rust.find_root(member_file) == ws,
    tostring(rust.find_root(member_file))
  )

  check(
    "inherited workspace edition",
    rust.edition(member_file) == "2024",
    rust.edition(member_file)
  )

  -- Standalone crate.
  local solo = vim.fn.tempname()

  write(
    j(solo, "Cargo.toml"),
    {
      "[package]",
      'name = "solo"',
      'edition = "2018"',
    }
  )

  write(
    j(solo, "src", "main.rs"),
    { "" }
  )

  local solo_file = j(
    solo,
    "src",
    "main.rs"
  )

  check(
    "standalone crate root",
    rust.find_root(solo_file) == solo
  )

  check(
    "standalone crate edition",
    rust.edition(solo_file) == "2018"
  )

  -- Default edition.
  local default = vim.fn.tempname()

  write(
    j(default, "Cargo.toml"),
    {
      "[package]",
      'name = "default"',
    }
  )

  write(
    j(default, "src", "main.rs"),
    { "" }
  )

  local default_file = j(
    default,
    "src",
    "main.rs"
  )

  check(
    "default crate edition",
    rust.edition(default_file) == "2021"
  )

  -- File outside a Cargo project.
  local none = vim.fn.tempname()

  write(
    j(none, "main.rs"),
    { "" }
  )

  local outside_file = j(none, "main.rs")

  check(
    "no Cargo root",
    rust.find_root(outside_file) == nil
  )

  check(
    "default edition outside project",
    rust.edition(outside_file) == "2021"
  )

  -- Formatter edition argument.
  if conform_ok then
    local args_fn =
      require("config.languages").formatters.rustfmt.prepend_args

    local args = args_fn(nil, {
      filename = member_file,
    })

    check(
      "rustfmt edition argument",
      args[1] == "--edition"
        and args[2] == "2024",
      vim.inspect(args)
    )
  end

  -- Cleanup temporary projects.
  for _, dir in ipairs({
    ws,
    solo,
    default,
    none,
  }) do
    vim.fn.delete(dir, "rf")
  end

  -- Cargo command must reject buffers outside Cargo projects.
  vim.cmd("enew")

  local notified = false
  local original_notify = vim.notify

  local ok, err = xpcall(function()
    vim.notify = function()
      notified = true
    end

    require("config.rust").cargo({
      "check",
    })
  end, debug.traceback)

  vim.notify = original_notify

  check(
    "Cargo guard execution",
    ok,
    err
  )

  check(
    "Cargo project guard",
    notified,
    ":Cargo should warn outside a Cargo project"
  )

  vim.cmd("bwipeout!")
end
```

### 8.1 Optional tool detection

At the end of the smoke test, report missing external tools without failing the offline test suite:

```lua
for _, exe in ipairs({
  "rust-analyzer",
  "rustfmt",
  "cargo",
}) do
  if vim.fn.executable(exe) == 0 then
    vim.notify(
      "rust: optional tool missing: " .. exe,
      vim.log.levels.WARN
    )
  end
end
```

These are external integration dependencies, not reasons to fail configuration-only tests.

### 8.2 Test limitations

The offline tests do not prove:

- rust-analyzer can start.
- Cargo can resolve dependencies.
- Clippy produces diagnostics.
- Conform invokes rustfmt correctly.
- rust-analyzer extension requests are supported.
- The configured server works with the installed Rust toolchain.

These require integration testing.

The tests should also be extended when the root finder or edition resolver gains support for additional Cargo manifest syntax.

## 9. Integration validation

Integration tests require the Rust toolchain and a working Cargo installation.

### 9.1 Create a test workspace

Create a small workspace:

```sh
mkdir rust-workspace
cd rust-workspace

cargo new --lib crates-a
cargo new --lib crates-b
```

Create a workspace manifest at the root:

```toml
[workspace]
resolver = "3"
members = [
  "crates-a",
  "crates-b",
]

[workspace.package]
edition = "2024"
```

For each member crate, use workspace edition inheritance:

```toml
[package]
name = "crates-a"
version = "0.1.0"
edition.workspace = true
```

Use the same arrangement for the second member.

### 9.2 Validate language-server attachment

Open files from both member crates.

Check:

```vim
:checkhealth vim.lsp
```

Verify:

- `rust_analyzer` starts successfully.
- Both member crates resolve to the workspace root.
- Only one rust-analyzer client is attached for the shared workspace.
- Hover displays signatures and documentation.
- `gd` navigates to definitions.
- `grr` lists references.
- Rename and code actions work.

### 9.3 Validate diagnostics

Introduce an intentional type error:

```rust
fn main() {
    let value: u32 = "invalid";
    println!("{value}");
}
```

Wait for rust-analyzer's check operation.

Verify that the diagnostic appears in Neovim.

Correct the code and confirm the diagnostic disappears.

### 9.4 Validate formatting

Create a file containing edition-specific syntax:

```rust
async fn example() {
    let value = async { 42 };
    println!("{}", value.await);
}
```

Introduce inconsistent indentation.

Run:

```vim
:Format
```

Verify:

- Conform selects `rustfmt`.
- The formatter receives the crate edition.
- The output is correctly formatted.
- No edition-related parse errors occur.
- The source file is not modified by a separate direct-to-file formatter invocation.

Also inspect:

```vim
:ConformInfo
```

### 9.5 Validate LSP formatting ownership

Run:

```vim
:lua =vim.lsp.get_clients({ name = "rust_analyzer" })[1].server_capabilities.documentFormattingProvider
```

Expected:

```lua
false
```

The Rust LSP must not become an alternative formatting authority.

### 9.6 Validate Cargo execution

Run:

```vim
:Cargo test
```

Verify:

- A terminal split opens.
- The command executes from the workspace root.
- Cargo runs the expected tests.
- The terminal displays its output.
- Pressing `q` closes the split.

Test argument forwarding:

```vim
:Cargo run -- --verbose
```

Test completion:

```vim
:Cargo <Tab>
```

### 9.7 Validate optional Clippy

Enable Clippy before initializing the language pack:

```lua
vim.g.config_rust_clippy = true
```

Restart Neovim or restart the Rust language server.

Verify:

```vim
:checkhealth vim.lsp
```

Introduce a Clippy-detectable issue and confirm that the diagnostic appears.

Example:

```rust
fn calculate() -> u32 {
    return 42;
}
```

Check that Clippy is available:

```sh
cargo clippy --version
```

### 9.8 Validate native inlay hints

Enable:

```lua
vim.g.config_rust_inlay_hints = true
```

Restart or reattach the language server.

Verify that supported type and parameter hints appear.

### 9.9 Validate extension commands

Test each command independently:

```vim
:RustExpandMacro
:RustOpenCargoToml
:RustOpenDocs
```

For each command, verify:

- The server is attached.
- The request method is supported.
- The response has the expected structure.
- Errors produce meaningful notifications.
- Unsupported methods do not crash Neovim.

These commands remain version-dependent until validated against the installed rust-analyzer release.

## 10. Checkpoint

Run the checks in the following order.

### 10.1 Static validation

```powershell
stylua --check .
```

```powershell
nvim -l scripts/check-syntax.lua
```

### 10.2 Offline smoke tests

Use the existing project startup and smoke-test conventions.

For a headless run with an isolated application name:

```powershell
$env:NVIM_APPNAME = "nvim-config"
nvim --headless -u init.lua -c "luafile scripts/smoke.lua" -c "qa!"
```

On systems where the configuration is already selected through `NVIM_APPNAME`, retain the repository's established invocation rather than introducing a second startup mechanism.

### 10.3 Integration validation

Complete the following:

- [ ] Rust filetype detection.
- [ ] Rust parser installation.
- [ ] rust-analyzer startup.
- [ ] Workspace-root resolution.
- [ ] Single server per workspace.
- [ ] Cross-crate navigation.
- [ ] Diagnostics.
- [ ] Edition-aware Conform formatting.
- [ ] LSP formatting disabled.
- [ ] Cargo terminal execution.
- [ ] Cargo argument forwarding.
- [ ] Cargo command completion.
- [ ] Optional Clippy diagnostics.
- [ ] Optional native inlay hints.
- [ ] Macro expansion compatibility.
- [ ] Cargo manifest navigation compatibility.
- [ ] External documentation compatibility.
- [ ] Windows compatibility.

### 10.4 Completion criteria

Rust support is ready for acceptance when:

1. Static validation passes.
2. Offline smoke tests pass.
3. Required external dependencies are detected correctly.
4. Workspace and standalone crate integration tests pass.
5. Conform formats using the correct edition.
6. Cargo commands execute from the expected root.
7. Optional features behave correctly when enabled.
8. Version-dependent extension commands either work or report unsupported functionality clearly.
9. Documentation reflects the implemented configuration.

Commit and tag the Rust support implementation only after the required checks pass.

## 11. Troubleshooting

| Symptom | Possible cause | Resolution |
|---|---|---|
| `rust_analyzer` never attaches | Missing executable | Verify `rust-analyzer --version` and PATH |
| Rust standard-library navigation fails | Missing `rust-src` | Run `rustup component add rust-src` |
| Rust formatting fails | Missing `rustfmt` | Run `rustup component add rustfmt` |
| Clippy diagnostics do not appear | Missing Clippy component | Run `rustup component add clippy` |
| Multiple rust-analyzer clients start | Workspace-root detection is incorrect | Inspect the resolved root for each member |
| Workspace member uses the wrong edition | Manifest inheritance was not resolved | Inspect package and workspace edition declarations |
| `async` syntax fails during formatting | Wrong edition passed to rustfmt | Inspect the resolved Conform command |
| Conform cannot format Rust | Incorrect formatter arguments or missing executable | Inspect `:ConformInfo` and the formatter definition |
| Formatting uses the LSP | Formatting capabilities were not disabled | Inspect the attached client's formatting capabilities |
| Cargo command cannot find a project | Current buffer is outside a Cargo project | Open a Rust file inside the project |
| Cargo command does not start | Cargo missing from PATH | Verify `cargo --version` |
| Cargo command uses the wrong directory | Root detection returned an unexpected path | Inspect `require("langs.rust").find_root()` |
| Macro expansion fails | Unsupported or changed extension request | Check the installed rust-analyzer version |
| Cargo manifest navigation fails | Extension request unsupported or response changed | Verify the request contract |
| Documentation command fails | Extension request or URL response changed | Verify server support and returned URL |
| Inlay hints do not appear | Option disabled or server method unsupported | Enable the option and inspect LSP capabilities |
| rust-analyzer competes with Cargo builds | Shared target directory or Cargo lock contention | Verify `cargo.targetDir` configuration |

Useful diagnostics:

```vim
:checkhealth vim.lsp
:ConformInfo
:messages
```

Check external tools:

```sh
rust-analyzer --version
rustfmt --version
cargo --version
cargo clippy --version
```

For rust-analyzer configuration diagnostics, its logs can be inspected using:

```sh
RA_LOG=rust_analyzer=info
```

Set the environment variable before starting Neovim, using the appropriate syntax for the operating system.

## 12. Architecture decisions

The following decisions govern future Rust support changes.

| Decision | Policy |
|---|---|
| Language server | rust-analyzer |
| LSP configuration | Native Neovim LSP API |
| Server definitions | Existing nvim-lspconfig |
| Formatter | rustfmt through Conform |
| Formatting ownership | Conform only |
| Formatting trigger | Manual by default |
| Linter | Clippy through rust-analyzer |
| Linting plugin | No nvim-lint |
| Workspace handling | Workspace root preferred |
| Edition detection | Cargo manifest and workspace inheritance |
| Cargo execution | Native terminal buffer and jobstart |
| Inlay hints | Native Neovim API |
| Parser | Existing Treesitter infrastructure |
| Debugging | Deferred to Stage 14 |
| New plugins | None |

### Deferred functionality

The following functionality is outside the initial Rust core-pack implementation:

- CodeLLDB debugging.
- DAP configuration.
- Advanced Cargo workspace management.
- Additional Rust-specific UI plugins.
- Automatic Rust toolchain installation.
- Advanced manifest parsing beyond the lightweight edition resolver.

Debugging belongs to Stage 14. Do not pull it into Stage 13.

## 13. References

Official documentation:

- [rust-analyzer – Installation](https://rust-analyzer.github.io/book/installation.html)
- [rust-analyzer – Configuration](https://rust-analyzer.github.io/book/configuration.html)
- [The Rust Programming Language](https://doc.rust-lang.org/book/)
- [Cargo Book](https://doc.rust-lang.org/cargo/)
- [rustfmt](https://github.com/rust-lang/rustfmt)
- [Clippy](https://doc.rust-lang.org/clippy/)
- [Neovim LSP documentation](https://neovim.io/doc/user/lsp.html)
- [Conform.nvim](https://github.com/stevearc/conform.nvim)
- [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig)

---

**Document ownership:** Stage 13 – Language Packs
**Core pack:** Rust
**Implementation principle:** Minimum installation. Compose the rest.
