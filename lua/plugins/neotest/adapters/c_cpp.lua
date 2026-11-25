-- Neotest C / C++ adapter.
-- CMake and CTest-based test discovery and execution.

local M = {}

local adapters_by_root = {}

local project_markers = {
  "CMakePresets.json",
  "compile_commands.json",
  ".clangd",
  ".clang-format",
  ".clang-tidy",
}

local function get_directory(path)
  if vim.fn.isdirectory(path) == 1 then
    return path
  end

  return vim.fs.dirname(path)
end

local function find_marker(directory, marker)
  local found = vim.fs.find(marker, {
    path = directory,
    upward = true,
    limit = 1,
    type = "file",
  })

  if #found == 0 then
    return nil
  end

  return vim.fs.dirname(found[1])
end

local function find_project_root(directory)
  local candidates = {}

  for _, marker in ipairs(project_markers) do
    local root = find_marker(directory, marker)

    if root then
      candidates[#candidates + 1] = root
    end
  end

  if #candidates == 0 then
    return nil
  end

  -- Select the nearest matching project root.
  table.sort(candidates, function(first, second)
    return #first > #second
  end)

  return candidates[1]
end

function M.find_root(path)
  if not path or path == "" then
    return nil
  end

  local directory = get_directory(path)

  if not directory then
    return nil
  end

  return find_project_root(directory)
end

local function get_adapter()
  return require("neotest-ctest").setup({
    root = find_project_root,
  })
end

function M.get_adapters(root)
  if not root or root == "" then
    return {}
  end

  root = vim.fs.normalize(root)

  if adapters_by_root[root] then
    return adapters_by_root[root]
  end

  local adapter = get_adapter()
  local adapters = { adapter }

  adapters_by_root[root] = adapters

  return adapters
end

return M
