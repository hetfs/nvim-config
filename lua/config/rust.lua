-- Stage 13: Native Rust and Cargo workflows.
--
-- This module provides an optional interactive Cargo command.
-- Rust language-server and formatter configuration belongs in lua/langs/rust.lua.
--
-- Cargo resolves workspace membership and root manifests. This module
-- deliberately avoids reimplementing Cargo's workspace rules in Lua.

local M = {}

local function notify(message, level)
  vim.notify(message, level, {
    title = "Rust",
  })
end

local function resolve_directory(path)
  if not path or path == "" then
    return vim.fn.getcwd()
  end

  path = vim.fs.normalize(vim.fn.fnamemodify(path, ":p"))

  if vim.fn.isdirectory(path) == 1 then
    return path
  end

  return vim.fs.dirname(path)
end

local function find_manifest(path)
  local dir = resolve_directory(path)

  if not dir then
    return nil
  end

  while dir do
    local manifest = vim.fs.joinpath(dir, "Cargo.toml")

    if vim.fn.filereadable(manifest) == 1 then
      return manifest
    end

    local parent = vim.fs.dirname(dir)

    if not parent or parent == dir then
      break
    end

    dir = parent
  end

  return nil
end

-- Resolve the actual Cargo workspace manifest.
--
-- Cargo handles workspace members, inherited workspace metadata,
-- nested workspaces, and excluded packages. Do not infer the workspace
-- root by scanning TOML section headers.
function M.find_root(path)
  if vim.fn.executable("cargo") ~= 1 then
    return nil, "Cargo is unavailable. Install the Rust toolchain first."
  end

  local manifest = find_manifest(path or vim.api.nvim_buf_get_name(0))

  if not manifest then
    return nil, "No Cargo.toml was found in the current directory or its parents."
  end

  local command = {
    "cargo",
    "locate-project",
    "--workspace",
    "--message-format",
    "plain",
    "--manifest-path",
    manifest,
  }

  -- This synchronous lookup is used by the explicitly invoked :Cargo
  -- command, not during startup or LSP attachment.
  local ok, result = pcall(function()
    return vim
      .system(command, {
        text = true,
      })
      :wait()
  end)

  if not ok then
    return nil, "Could not execute cargo locate-project: " .. tostring(result)
  end

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

  workspace_manifest = vim.fs.normalize(vim.fn.fnamemodify(workspace_manifest, ":p"))

  if vim.fn.filereadable(workspace_manifest) ~= 1 then
    return nil, "Cargo returned a workspace manifest that cannot be read: " .. workspace_manifest
  end

  return vim.fs.dirname(workspace_manifest)
end

local function run_cargo(opts)
  if vim.fn.executable("cargo") ~= 1 then
    notify("Cargo is unavailable. Install the Rust toolchain first.", vim.log.levels.WARN)
    return
  end

  local root, err = M.find_root()

  if not root then
    notify(err or "Could not determine the Cargo workspace root.", vim.log.levels.WARN)
    return
  end

  -- Keep arguments separate. Do not construct a shell command string.
  local command = { "cargo" }
  vim.list_extend(command, opts.fargs)

  -- Create a dedicated terminal window for the Cargo process.
  vim.cmd("botright 14new")

  local terminal_buf = vim.api.nvim_get_current_buf()
  local terminal_win = vim.api.nvim_get_current_win()

  local job = vim.fn.jobstart(command, {
    term = true,
    cwd = root,
  })

  if job <= 0 then
    -- Remove the unused terminal window and buffer.
    if vim.api.nvim_win_is_valid(terminal_win) then
      vim.api.nvim_win_close(terminal_win, true)
    end

    if vim.api.nvim_buf_is_valid(terminal_buf) then
      vim.api.nvim_buf_delete(terminal_buf, {
        force = true,
      })
    end

    notify("Could not start the Cargo process.", vim.log.levels.ERROR)
    return
  end

  vim.cmd("startinsert")
end

function M.setup()
  vim.api.nvim_create_user_command("Cargo", run_cargo, {
    nargs = "+",
    desc = "Run a Cargo subcommand in the current Rust workspace",
    force = true,
  })
end

return M
