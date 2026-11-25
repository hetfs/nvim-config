-- Neotest adapter registry.
-- Registers the nearest applicable project and prevents overlapping roots.

local M = {}

local adapter_modules = {
  require("plugins.neotest.adapters.python"),
  require("plugins.neotest.adapters.javascript"),
  require("plugins.neotest.adapters.go"),
  require("plugins.neotest.adapters.rust"),
  require("plugins.neotest.adapters.lua"),
  require("plugins.neotest.adapters.c_cpp"),
  require("plugins.neotest.adapters.bash"),
}

local registered_projects = {}
local warned_internal_api = false

local is_windows = vim.fn.has("win32") == 1

-- ============================================================
-- Path utilities
-- ============================================================

local function normalize(path)
  if type(path) ~= "string" or path == "" then
    return nil
  end

  path = vim.fn.fnamemodify(path, ":p")
  path = vim.fs.normalize(path)
  path = path:gsub("\\", "/")

  -- Preserve filesystem roots.
  while #path > 1 and path:sub(-1) == "/" do
    if is_windows and path:match("^%a:/$") then
      break
    end

    path = path:sub(1, -2)
  end

  return path
end

local function path_key(path)
  if is_windows then
    return path:lower()
  end

  return path
end

local function is_same_or_nested(path, root)
  path = path_key(path)
  root = path_key(root)

  if path == root then
    return true
  end

  local prefix = root:sub(-1) == "/" and root or root .. "/"

  return path:sub(1, #prefix) == prefix
end

local function paths_overlap(first, second)
  return is_same_or_nested(first, second) or is_same_or_nested(second, first)
end

local function get_project_key(root)
  -- Match Neotest's setup_project() path normalization.
  local path = vim.fn.fnamemodify(root .. "/", ":p")

  return path:sub(1, -2)
end

-- ============================================================
-- Adapter utilities
-- ============================================================

local function add_adapters(target, adapters)
  local known = {}

  for _, adapter in ipairs(target) do
    known[adapter] = true
  end

  for _, adapter in ipairs(adapters) do
    if not known[adapter] then
      target[#target + 1] = adapter
      known[adapter] = true
    end
  end
end

local function same_adapters(first, second)
  if not first or #first ~= #second then
    return false
  end

  -- Preserve adapter ordering because Neotest may evaluate
  -- matching test files according to registration order.
  for index, adapter in ipairs(first) do
    if adapter ~= second[index] then
      return false
    end
  end

  return true
end

-- ============================================================
-- Neotest internal project access
-- ============================================================

-- Neotest does not expose a public project-removal API.
-- Keep access to its internal project table isolated here.

local function internal_projects()
  local ok, config = pcall(require, "neotest.config")

  if not ok or type(config) ~= "table" then
    return nil
  end

  if type(config.projects) ~= "table" then
    return nil
  end

  return config.projects
end

function M.internal_api_available()
  return internal_projects() ~= nil
end

local function warn_internal_api()
  if warned_internal_api then
    return
  end

  warned_internal_api = true

  vim.notify("Neotest registry: cannot remove overlapping projects because neotest.config.projects is unavailable", vim.log.levels.WARN)
end

-- ============================================================
-- Project lifecycle
-- ============================================================

local function has_overlapping_projects(root)
  for _, project in pairs(registered_projects) do
    if paths_overlap(project.root, root) then
      return true
    end
  end

  return false
end

local function remove_overlapping_projects(root)
  local to_remove = {}

  for root_key, project in pairs(registered_projects) do
    if paths_overlap(project.root, root) then
      to_remove[#to_remove + 1] = {
        root_key = root_key,
        project_key = project.key,
      }
    end
  end

  if #to_remove == 0 then
    return true
  end

  -- Verify API availability before modifying registry state.
  local projects = internal_projects()

  if not projects then
    warn_internal_api()
    return false
  end

  -- Remove all overlapping Neotest entries.
  for _, entry in ipairs(to_remove) do
    projects[entry.project_key] = nil
  end

  -- Update local registry only after internal cleanup succeeds.
  for _, entry in ipairs(to_remove) do
    registered_projects[entry.root_key] = nil
  end

  return true
end

local function register_project(root, adapters)
  if not root or #adapters == 0 then
    return
  end

  root = normalize(root)

  if not root then
    return
  end

  local root_key = path_key(root)
  local existing = registered_projects[root_key]

  -- Avoid unnecessary project re-registration.
  if existing and same_adapters(existing.adapters, adapters) then
    return
  end

  -- Keep only one registry-owned project in an overlapping hierarchy.
  if not remove_overlapping_projects(root) then
    return
  end

  -- Defensive check: never register over an entry that could not
  -- be removed from the registry.
  if has_overlapping_projects(root) then
    return
  end

  local project_key = get_project_key(root)

  -- Remove an untracked or stale entry before replacing its configuration.
  local projects = internal_projects()

  if projects then
    projects[project_key] = nil
  end

  local ok, err = pcall(function()
    require("neotest").setup_project(root .. "/", {
      adapters = adapters,
    })
  end)

  if not ok then
    vim.notify("Neotest registry: failed to register project:\n" .. root .. "\n" .. tostring(err), vim.log.levels.ERROR)

    return
  end

  registered_projects[root_key] = {
    root = root,
    key = project_key,
    adapters = adapters,
  }
end

-- ============================================================
-- Project discovery
-- ============================================================

local function get_project(path)
  local candidates = {}

  local function add_candidate(root, module)
    if not root then
      return
    end

    root = normalize(root)

    if not root then
      return
    end

    local root_key = path_key(root)

    for _, candidate in ipairs(candidates) do
      if candidate.key == root_key then
        candidate.modules[#candidate.modules + 1] = module
        return
      end
    end

    candidates[#candidates + 1] = {
      root = root,
      key = root_key,
      modules = { module },
    }
  end

  -- Identify applicable roots without loading adapter implementations.
  for _, module in ipairs(adapter_modules) do
    add_candidate(module.find_root(path), module)
  end

  if #candidates == 0 then
    return nil
  end

  -- Prefer the deepest applicable project root.
  table.sort(candidates, function(first, second)
    return #first.root > #second.root
  end)

  local selected = candidates[1]
  local adapters = {}

  -- Load only adapters belonging to the selected project root.
  for _, module in ipairs(selected.modules) do
    add_adapters(adapters, module.get_adapters(selected.root))
  end

  if #adapters == 0 then
    return nil
  end

  return {
    root = selected.root,
    adapters = adapters,
  }
end

-- ============================================================
-- Public API
-- ============================================================

function M.register(path)
  if type(path) ~= "string" or path == "" then
    return
  end

  path = normalize(path)

  if not path then
    return
  end

  local project = get_project(path)

  -- An unrecognized path does not invalidate existing registrations.
  if not project then
    return
  end

  register_project(project.root, project.adapters)
end

-- ============================================================
-- Autocommands
-- ============================================================

local function register_current_context()
  local buffer = vim.api.nvim_get_current_buf()
  local path = vim.api.nvim_buf_get_name(buffer)

  if vim.bo[buffer].buftype == "" and path ~= "" then
    M.register(path)
  else
    M.register(vim.fn.getcwd())
  end
end

function M.setup_autocmds()
  local group = vim.api.nvim_create_augroup("NeotestProjectAdapters", {
    clear = true,
  })

  vim.api.nvim_create_autocmd("BufEnter", {
    group = group,
    callback = function(event)
      local buffer = event.buf
      local path = vim.api.nvim_buf_get_name(buffer)

      if vim.bo[buffer].buftype == "" and path ~= "" then
        M.register(path)
      end
    end,
  })

  vim.api.nvim_create_autocmd("DirChanged", {
    group = group,
    callback = register_current_context,
  })

  register_current_context()
end

return M
