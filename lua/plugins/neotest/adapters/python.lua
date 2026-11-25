-- Neotest Python adapter.
-- Pytest-based test discovery and execution, one adapter per project root.

local M = {}

local markers = {
  "pyproject.toml",
  "pytest.ini",
  "setup.cfg",
  "tox.ini",
  "setup.py",
}

local adapters = {}
local global_interpreter
local global_resolved = false
local warned_missing = false
local warned_failure = false

local is_windows = vim.fn.has("win32") == 1

local function get_directory(path)
  if vim.fn.isdirectory(path) == 1 then
    return path
  end

  return vim.fs.dirname(path)
end

local function normalize_path(path)
  if not path or path == "" then
    return nil
  end

  local normalized = vim.fs.normalize(path):gsub("\\", "/")

  if #normalized > 1 then
    normalized = normalized:gsub("/+$", "")
  end

  return normalized
end

local function cache_key(root)
  local key = normalize_path(root) or ""

  return is_windows and key:lower() or key
end

local function is_within_root(path, root)
  path = normalize_path(path)
  root = normalize_path(root)

  if not path or not root then
    return false
  end

  if is_windows then
    path = path:lower()
    root = root:lower()
  end

  return path == root or path:sub(1, #root + 1) == root .. "/"
end

local function is_test_file(path)
  if type(path) ~= "string" then
    return false
  end

  -- Normalize Windows and Unix path separators.
  local normalized = path:gsub("\\", "/")

  if not normalized:match("%.py$") then
    return false
  end

  local filename = normalized:match("([^/]+)$")

  if not filename then
    return false
  end

  return filename:match("^test_.*%.py$") ~= nil or filename:match("_test%.py$") ~= nil
end

local function venv_python(venv)
  local relative = is_windows and { "Scripts", "python.exe" } or { "bin", "python" }

  local candidate = vim.fs.joinpath(venv, unpack(relative))

  if vim.fn.executable(candidate) == 1 then
    return candidate
  end

  return nil
end

local function global_python()
  if global_resolved then
    return global_interpreter
  end

  -- On Windows, python3 may resolve to a Microsoft Store stub.
  local names = is_windows and { "python", "python3" } or { "python3", "python" }

  for _, name in ipairs(names) do
    local path = vim.fn.exepath(name)

    if path ~= "" then
      global_interpreter = path
      break
    end
  end

  global_resolved = true

  return global_interpreter
end

local function resolve_interpreter(root)
  if root and root ~= "" then
    local active = vim.env.VIRTUAL_ENV

    -- Reuse an active environment only when it belongs to this project.
    if active and active ~= "" and is_within_root(active, root) then
      local python = venv_python(active)

      if python then
        return python
      end
    end

    -- Prefer project-local environments.
    for _, name in ipairs({ ".venv", "venv" }) do
      local python = venv_python(vim.fs.joinpath(root, name))

      if python then
        return python
      end
    end
  end

  return global_python()
end

local function warn_once(message, flag)
  if flag == "missing" then
    if warned_missing then
      return
    end

    warned_missing = true
  else
    if warned_failure then
      return
    end

    warned_failure = true
  end

  vim.notify(message, vim.log.levels.WARN)
end

function M.find_root(path)
  if not path or path == "" then
    return nil
  end

  local directory = get_directory(path)

  if not directory or directory == "" then
    return nil
  end

  local found = vim.fs.find(markers, {
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
  local key = cache_key(root)

  if adapters[key] then
    return { adapters[key] }
  end

  local ok, factory = pcall(require, "neotest-python")

  if not ok then
    warn_once("Neotest: neotest-python is not installed; Python adapter disabled", "missing")

    return {}
  end

  local success, adapter = pcall(factory, {
    python = resolve_interpreter(root),
    runner = "pytest",
    is_test_file = is_test_file,
  })

  if not success then
    warn_once("Neotest: failed to initialize neotest-python; Python adapter disabled: " .. tostring(adapter), "failure")

    return {}
  end

  adapters[key] = adapter

  return { adapter }
end

return M
