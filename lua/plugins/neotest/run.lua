-- Neotest run helper.
-- Normalizes test paths and provides safe run entrypoints.

local M = {}

local function normalize_path(path)
  if type(path) ~= "string" or path == "" then
    return nil
  end

  path = vim.fn.fnamemodify(path, ":p")

  if vim.fn.has("win32") == 1 then
    path = path:gsub("/", "\\")
  end

  return path
end

local function get_current_path()
  local path = vim.api.nvim_buf_get_name(0)

  if path == "" then
    return nil
  end

  return path
end

local function notify(message, level)
  vim.notify(message, level, { title = "Neotest" })
end

function M.run(path, ...)
  path = normalize_path(path or get_current_path())

  if not path then
    notify("No valid test file path provided", vim.log.levels.WARN)
    return
  end

  if vim.fn.filereadable(path) ~= 1 then
    notify("Test file does not exist: " .. path, vim.log.levels.WARN)
    return
  end

  local ok, neotest = pcall(require, "neotest")

  if not ok then
    notify("Neotest is not available: " .. tostring(neotest), vim.log.levels.ERROR)
    return
  end

  return neotest.run.run(path, ...)
end

function M.run_current(...)
  return M.run(get_current_path(), ...)
end

return M
