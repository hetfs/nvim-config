-- Neotest Lua adapters.
-- Supports Plenary and standalone Busted projects.

local M = {}

local adapters_by_root = {}

local plenary_markers = {
  "minimal_init.lua",
  "minimal_init.vim",
  "testrc",
  "tests/minimal_init.lua",
  "tests/minimal_init.vim",
  "tests/init.vim",
  "test/init.vim",
}

local function get_directory(path)
  if vim.fn.isdirectory(path) == 1 then
    return path
  end

  return vim.fs.dirname(path)
end

local function has_file(root, name)
  return vim.fn.filereadable(vim.fs.joinpath(root, name)) == 1
end

local function has_busted_config(root)
  return has_file(root, ".busted")
end

local function has_plenary_config(root)
  for _, marker in ipairs(plenary_markers) do
    if has_file(root, marker) then
      return true
    end
  end

  return false
end

local function find_project_root(directory)
  -- Explicit Busted configuration takes precedence.
  local busted_root = vim.fs.root(directory, ".busted")

  if busted_root then
    return busted_root
  end

  -- Plenary requires explicit test bootstrap configuration.
  local project_root = vim.fs.root(directory, ".git")

  if project_root and has_plenary_config(project_root) then
    return project_root
  end

  return nil
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

local function get_adapter(root)
  -- Explicit Busted configuration takes precedence.
  if has_busted_config(root) then
    return require("neotest-busted")({})
  end

  -- Plenary projects require a recognized bootstrap file.
  if has_plenary_config(root) then
    return require("neotest-plenary")
  end

  return nil
end

function M.get_adapters(root)
  if not root or root == "" then
    return {}
  end

  root = vim.fs.normalize(root)

  if adapters_by_root[root] then
    return adapters_by_root[root]
  end

  local adapter = get_adapter(root)
  local adapters = {}

  if adapter then
    adapters[#adapters + 1] = adapter
  end

  adapters_by_root[root] = adapters

  return adapters
end

return M
