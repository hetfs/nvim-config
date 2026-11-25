-- Neotest Bash adapter.
-- Bashunit-based test discovery and execution.

local M = {}

local adapter
local warned_failure = false

local MARKERS = {
  { ".bashunitrc" },
  { "bashunit" },
  { "lib", "bashunit" },
}

local function get_directory(path)
  if vim.fn.isdirectory(path) == 1 then
    return path
  end

  return vim.fs.dirname(path)
end

local function has_bashunit_marker(directory)
  for _, parts in ipairs(MARKERS) do
    if vim.fn.filereadable(vim.fs.joinpath(directory, unpack(parts))) == 1 then
      return true
    end
  end

  return false
end

function M.find_root(path)
  if not path or path == "" then
    return nil
  end

  local directory = get_directory(path)

  if not directory or directory == "" then
    return nil
  end

  -- Check the starting directory before walking its parents.
  if has_bashunit_marker(directory) then
    return directory
  end

  for parent in vim.fs.parents(directory) do
    if has_bashunit_marker(parent) then
      return parent
    end
  end

  return nil
end

function M.get_adapters(_root)
  if not adapter then
    local ok, result = pcall(function()
      return require("neotest-bash")({})
    end)

    if not ok then
      if not warned_failure then
        warned_failure = true
        vim.notify("Neotest: failed to load neotest-bash; Bash adapter disabled: " .. tostring(result), vim.log.levels.WARN)
      end

      return {}
    end

    adapter = result
  end

  return { adapter }
end

return M
