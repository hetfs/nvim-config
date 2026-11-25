-- Neotest JavaScript / TypeScript adapters.
-- Supports Jest and Vitest.

local M = {}

local adapters_by_root = {}

local function get_directory(path)
  if vim.fn.isdirectory(path) == 1 then
    return path
  end

  return vim.fs.dirname(path)
end

local function read_package_json(root)
  local file = vim.fs.joinpath(root, "package.json")

  if vim.fn.filereadable(file) ~= 1 then
    return nil
  end

  local ok, content = pcall(vim.fn.readfile, file)

  if not ok then
    return nil
  end

  local decoded, package = pcall(vim.json.decode, table.concat(content, "\n"))

  if not decoded or type(package) ~= "table" then
    return nil
  end

  return package
end

local function has_dependency(package, name)
  local sections = {
    "dependencies",
    "devDependencies",
    "peerDependencies",
    "optionalDependencies",
  }

  for _, section in ipairs(sections) do
    local dependencies = package[section]

    if type(dependencies) == "table" and type(dependencies[name]) == "string" then
      return true
    end
  end

  return false
end

local function has_script(package, executable)
  local scripts = package.scripts

  if type(scripts) ~= "table" then
    return false
  end

  for _, command in pairs(scripts) do
    if type(command) == "string" and command:match("%f[%w]" .. executable .. "%f[%W]") then
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

  if not directory then
    return nil
  end

  local found = vim.fs.find("package.json", {
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

function M.get_adapters(root)
  if not root or root == "" then
    return {}
  end

  root = vim.fs.normalize(root)

  if adapters_by_root[root] then
    return adapters_by_root[root]
  end

  local package = read_package_json(root)

  if not package then
    return {}
  end

  local adapters = {}

  local has_vitest = has_dependency(package, "vitest") or has_script(package, "vitest")

  local has_jest = has_dependency(package, "jest") or has_dependency(package, "@jest/core") or has_script(package, "jest")

  if has_jest then
    adapters[#adapters + 1] = require("neotest-jest")({})
  end

  if has_vitest then
    adapters[#adapters + 1] = require("neotest-vitest")
  end

  adapters_by_root[root] = adapters

  return adapters
end

return M
