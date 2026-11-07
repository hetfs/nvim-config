-- Stage 13: Rust language pack.
--
-- rust-analyzer provides language intelligence and diagnostics.
-- Conform owns Rust formatting through rustfmt.
-- Tree-sitter parser ownership is declared by filetype.
--
-- External tools are never installed during startup.

local M = {
  formatters = {
    rust = { "rustfmt" },
  },

  parser_by_filetype = {
    rust = "rust",
  },
}

local uv = vim.uv

-- ============================================================
-- Filesystem Helpers
-- ============================================================

local function is_file(path)
  local stat = uv.fs_stat(path)

  return stat ~= nil and stat.type == "file"
end

local function parent_dir(path)
  local parent = vim.fs.dirname(path)

  if parent == path then
    return nil
  end

  return parent
end

local function normalize_path(path)
  return vim.fs.normalize(vim.fn.fnamemodify(path, ":p"))
end

local function get_start_directory(path)
  if type(path) ~= "string" or path == "" then
    return nil
  end

  local absolute = normalize_path(path)
  local stat = uv.fs_stat(absolute)

  if stat and stat.type == "directory" then
    return absolute
  end

  return vim.fs.dirname(absolute)
end

-- Find the nearest Cargo.toml or rust-project.json.
--
-- Cargo.toml takes precedence when both markers exist
-- in the same directory.
local function find_nearest_marker(start_dir)
  local dir = start_dir

  while dir do
    local manifest = vim.fs.joinpath(dir, "Cargo.toml")
    local project = vim.fs.joinpath(dir, "rust-project.json")

    if is_file(manifest) then
      return {
        kind = "cargo",
        path = manifest,
        dir = dir,
      }
    end

    if is_file(project) then
      return {
        kind = "rust-project",
        path = project,
        dir = dir,
      }
    end

    dir = parent_dir(dir)
  end

  return nil
end

-- ============================================================
-- Cargo Workspace Resolution
-- ============================================================

local function cargo_command(manifest)
  return {
    "cargo",
    "locate-project",
    "--workspace",
    "--message-format",
    "plain",
    "--manifest-path",
    manifest,
  }
end

local function parse_cargo_result(result)
  if result.code ~= 0 then
    local detail = vim.trim(result.stderr or "")

    if detail == "" then
      detail = "Cargo exited with status " .. result.code .. "."
    end

    return nil, "Could not resolve the Cargo workspace: " .. detail
  end

  local workspace_manifest = vim.trim(result.stdout or "")

  if workspace_manifest == "" then
    return nil, "Cargo returned an empty workspace manifest path."
  end

  workspace_manifest = normalize_path(workspace_manifest)

  if not is_file(workspace_manifest) then
    return nil, "Cargo returned a workspace manifest that cannot be read: " .. workspace_manifest
  end

  return vim.fs.dirname(workspace_manifest)
end

-- Resolve the Cargo workspace synchronously.
--
-- This function is intended for explicit calls and tests.
-- It is not used synchronously during LSP attachment.
local function resolve_cargo_root(manifest)
  if vim.fn.executable("cargo") ~= 1 then
    return vim.fs.dirname(manifest), "Cargo is unavailable; using the nearest Cargo.toml directory."
  end

  local ok, result = pcall(function()
    return vim
      .system(cargo_command(manifest), {
        text = true,
        cwd = vim.fs.dirname(manifest),
      })
      :wait()
  end)

  if not ok then
    return nil, "Could not execute cargo locate-project: " .. tostring(result)
  end

  return parse_cargo_result(result)
end

-- Resolve the Cargo workspace asynchronously for the LSP.
local function resolve_cargo_root_async(manifest, callback)
  if vim.fn.executable("cargo") ~= 1 then
    callback(vim.fs.dirname(manifest), "Cargo is unavailable; using the nearest Cargo.toml directory.")
    return
  end

  local ok, process = pcall(function()
    return vim.system(
      cargo_command(manifest),
      {
        text = true,
        cwd = vim.fs.dirname(manifest),
      },
      vim.schedule_wrap(function(result)
        local root, err = parse_cargo_result(result)
        callback(root, err)
      end)
    )
  end)

  if not ok then
    callback(nil, "Could not execute cargo locate-project: " .. tostring(process))
  end
end

-- ============================================================
-- Public Root Resolver
-- ============================================================

-- Resolve the nearest Rust project root.
--
-- Cargo projects use Cargo's workspace resolution.
-- Standalone and excluded crates use their Cargo package root.
-- rust-project.json projects use the marker directory.
--
-- Returns:
--   root, nil       on successful resolution
--   root, warning   when Cargo is unavailable and fallback is used
--   nil, error      when resolution fails
function M.find_root(path)
  local dir = get_start_directory(path)

  if not dir then
    return nil, "A valid file or directory path is required."
  end

  local marker = find_nearest_marker(dir)

  if not marker then
    return nil
  end

  if marker.kind == "rust-project" then
    return marker.dir
  end

  return resolve_cargo_root(marker.path)
end

-- ============================================================
-- Native LSP Root Callback
-- ============================================================

local function root_dir(bufnr, on_dir)
  local path = vim.api.nvim_buf_get_name(bufnr)

  if path == "" then
    return
  end

  local dir = get_start_directory(path)

  if not dir then
    return
  end

  local marker = find_nearest_marker(dir)

  if not marker then
    return
  end

  if marker.kind == "rust-project" then
    on_dir(marker.dir)
    return
  end

  resolve_cargo_root_async(marker.path, function(root, err)
    if not vim.api.nvim_buf_is_valid(bufnr) then
      return
    end

    -- Do not attach using a root resolved for a previous buffer path.
    local current_path = vim.api.nvim_buf_get_name(bufnr)

    if current_path == "" or normalize_path(current_path) ~= normalize_path(path) then
      return
    end

    if not root then
      vim.notify("Rust: " .. (err or "Could not determine the Cargo workspace root."), vim.log.levels.WARN)
      return
    end

    if err then
      vim.notify("Rust: " .. err, vim.log.levels.WARN)
    end

    on_dir(root)
  end)
end

-- ============================================================
-- Rust LSP Attachment
-- ============================================================

local function setup_lsp_attach()
  local group = vim.api.nvim_create_augroup("nvim_config_rust_lsp", {
    clear = true,
  })

  vim.api.nvim_create_autocmd("LspAttach", {
    group = group,
    desc = "Disable rust-analyzer formatting",
    callback = function(event)
      local client = vim.lsp.get_client_by_id(event.data.client_id)

      if not client or client.name ~= "rust_analyzer" then
        return
      end

      -- Conform is the sole Rust formatting authority.
      client.server_capabilities.documentFormattingProvider = false
      client.server_capabilities.documentRangeFormattingProvider = false
    end,
  })
end

-- ============================================================
-- Setup
-- ============================================================

function M.setup()
  setup_lsp_attach()

  if vim.fn.executable("rust-analyzer") ~= 1 then
    vim.notify("Rust: rust-analyzer is unavailable; install it using the Rust toolchain setup", vim.log.levels.WARN)
    return
  end

  local language_config = require("config.languages")
  local tools = language_config.tools or {}

  local use_clippy = tools.rust_clippy == true
  local clippy_available = vim.fn.executable("cargo-clippy") == 1

  if use_clippy and not clippy_available then
    vim.notify("Rust: Clippy is enabled but cargo-clippy is unavailable; using cargo check", vim.log.levels.WARN)
  end

  local check_command = use_clippy and clippy_available and "clippy" or "check"

  vim.lsp.config("rust_analyzer", {
    filetypes = { "rust" },
    root_dir = root_dir,

    settings = {
      ["rust-analyzer"] = {
        cargo = {
          allFeatures = false,

          buildScripts = {
            enable = true,
          },
        },

        procMacro = {
          enable = true,
        },

        check = {
          command = check_command,
        },
      },
    },
  })

  vim.lsp.enable("rust_analyzer")
end

return M
