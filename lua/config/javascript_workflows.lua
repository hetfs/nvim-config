-- JavaScript and TypeScript project workflows.
--
-- This module is independent of language-pack metadata and LSP setup.
-- It detects project frameworks, resolves package managers, and runs
-- existing package scripts without installing dependencies.

local M = {}

local allowed_scripts = {
  dev = true,
  start = true,
  test = true,
  build = true,
  lint = true,
  typecheck = true,
  check = true,
}

local lockfiles = {
  npm = {
    "package-lock.json",
    "npm-shrinkwrap.json",
  },
  pnpm = {
    "pnpm-lock.yaml",
  },
  yarn = {
    "yarn.lock",
  },
  bun = {
    "bun.lock",
    "bun.lockb",
  },
}

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, {
    title = "JavaScript workflow",
  })
end

local function is_file(path)
  return vim.uv.fs_stat(path) ~= nil
end

local function read_manifest(path)
  local lines = vim.fn.readfile(path)

  if #lines == 0 then
    return nil, "package.json is empty: " .. path
  end

  local ok, manifest = pcall(vim.json.decode, table.concat(lines, "\n"))

  if not ok or type(manifest) ~= "table" then
    return nil, "Invalid package.json: " .. path
  end

  return manifest
end

local function parent_directory(path)
  local parent = vim.fs.dirname(path)

  if parent == path then
    return nil
  end

  return parent
end

local function find_nearest_manifest(start_directory)
  local matches = vim.fs.find("package.json", {
    path = start_directory,
    upward = true,
    type = "file",
  })

  return matches[1]
end

local function has_workspace_marker(directory, manifest)
  if manifest.workspaces ~= nil then
    return true
  end

  return is_file(vim.fs.joinpath(directory, "pnpm-workspace.yaml"))
end

local function find_workspace_root(package_root)
  local directory = package_root

  while directory do
    local manifest_path = vim.fs.joinpath(directory, "package.json")

    if is_file(manifest_path) then
      local manifest, err = read_manifest(manifest_path)

      if not manifest then
        return nil, nil, err
      end

      if has_workspace_marker(directory, manifest) then
        return directory, manifest
      end
    end

    directory = parent_directory(directory)
  end

  local manifest_path = vim.fs.joinpath(package_root, "package.json")
  local manifest, err = read_manifest(manifest_path)

  if not manifest then
    return nil, nil, err
  end

  return package_root, manifest
end

local function collect_dependencies(manifest)
  local dependencies = {}

  for _, field in ipairs({
    "dependencies",
    "devDependencies",
    "optionalDependencies",
  }) do
    local values = manifest[field]

    if type(values) == "table" then
      for name, version in pairs(values) do
        if type(name) == "string" and version ~= nil then
          dependencies[name] = true
        end
      end
    end
  end

  return dependencies
end

local function detect_frameworks(manifest)
  local dependencies = collect_dependencies(manifest)

  local expo = dependencies.expo == true
  local react_native_dependency = dependencies["react-native"] == true

  return {
    expo = expo,
    -- Expo is classified separately because it uses React Native.
    react_native = react_native_dependency and not expo,
    react_native_dependency = react_native_dependency,
    nextjs = dependencies.next == true,
  }
end

local function parse_package_manager(value)
  if type(value) ~= "string" then
    return nil, "packageManager must be a string"
  end

  local name = value:match("^([%w%-]+)@")

  if not name or not lockfiles[name] then
    return nil, "Unsupported packageManager declaration: " .. value
  end

  return name
end

local function resolve_package_manager(context)
  local package_value = context.package.packageManager
  local workspace_value = context.workspace_package.packageManager

  local package_manager
  local workspace_manager

  if package_value ~= nil then
    local err

    package_manager, err = parse_package_manager(package_value)

    if not package_manager then
      return nil, err
    end
  end

  if workspace_value ~= nil then
    local err

    workspace_manager, err = parse_package_manager(workspace_value)

    if not workspace_manager then
      return nil, err
    end
  end

  if package_manager and workspace_manager and package_manager ~= workspace_manager then
    return nil, string.format("Conflicting packageManager declarations: package uses %s, workspace uses %s", package_manager, workspace_manager)
  end

  if package_manager or workspace_manager then
    return package_manager or workspace_manager
  end

  local detected = {}

  for manager, names in pairs(lockfiles) do
    for _, name in ipairs(names) do
      if is_file(vim.fs.joinpath(context.workspace_root, name)) then
        detected[manager] = true
      end
    end
  end

  local managers = {}

  for manager in pairs(detected) do
    managers[#managers + 1] = manager
  end

  table.sort(managers)

  if #managers == 0 then
    return nil, "No packageManager declaration or recognized lockfile was found"
  end

  if #managers > 1 then
    return nil, "Conflicting package-manager lockfiles: " .. table.concat(managers, ", ")
  end

  return managers[1]
end

-- Resolve the package containing the current buffer and its workspace.
function M.resolve(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  if not vim.api.nvim_buf_is_valid(bufnr) then
    return nil, "Invalid buffer"
  end

  local filename = vim.api.nvim_buf_get_name(bufnr)

  if filename == "" then
    return nil, "Save the current file before running a package workflow"
  end

  local start_directory = vim.fs.dirname(vim.fn.fnamemodify(filename, ":p"))
  local package_file = find_nearest_manifest(start_directory)

  if not package_file then
    return nil, "No package.json found above the current file"
  end

  local package, err = read_manifest(package_file)

  if not package then
    return nil, err
  end

  local package_root = vim.fs.dirname(package_file)
  local workspace_root, workspace_package, workspace_err = find_workspace_root(package_root)

  if not workspace_root then
    return nil, workspace_err
  end

  local context = {
    package = package,
    package_file = package_file,
    package_root = package_root,
    frameworks = detect_frameworks(package),
    workspace_package = workspace_package,
    workspace_root = workspace_root,
  }

  local manager, manager_err = resolve_package_manager(context)

  if not manager then
    return nil, manager_err
  end

  context.package_manager = manager

  return context
end

-- Select the first configured script from the supplied candidates.
function M.select_script(context, candidates)
  if type(candidates) ~= "table" then
    return nil, "Script candidates must be a table"
  end

  local scripts = context.package.scripts

  if type(scripts) ~= "table" then
    return nil, "The package.json does not define a scripts object"
  end

  for _, name in ipairs(candidates) do
    if not allowed_scripts[name] then
      return nil, "Script is not in the approved workflow list: " .. tostring(name)
    end

    local value = scripts[name]

    if type(value) == "string" and vim.trim(value) ~= "" then
      return name
    end
  end

  return nil, "None of the expected scripts exists: " .. table.concat(candidates, ", ")
end

local function resolve_executable(manager)
  local executable = vim.fn.exepath(manager)

  if executable ~= "" then
    return executable, {}
  end

  -- Corepack can provide pnpm and Yarn without downloading packages here.
  if manager == "pnpm" or manager == "yarn" then
    local corepack = vim.fn.exepath("corepack")

    if corepack ~= "" then
      return corepack, { manager }
    end
  end

  return nil, nil
end

local function build_command(executable, prefix, manager, script)
  local args = {}

  vim.list_extend(args, prefix)
  vim.list_extend(args, { "run", script })

  if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
    local command_processor = vim.env.COMSPEC or "cmd.exe"
    local command = '"' .. executable .. '"'

    for _, arg in ipairs(args) do
      command = command .. " " .. arg
    end

    return {
      command_processor,
      "/d",
      "/s",
      "/c",
      '"' .. command .. '"',
    }
  end

  return vim.list_extend({ executable }, args)
end

local function run_terminal(command, package_root, script)
  vim.cmd("botright 12new")

  local terminal_buffer = vim.api.nvim_get_current_buf()

  vim.bo[terminal_buffer].bufhidden = "hide"
  vim.bo[terminal_buffer].swapfile = false

  local ok, job = pcall(vim.fn.jobstart, command, {
    cwd = package_root,
    term = true,
  })

  if not ok or job <= 0 then
    vim.cmd("close")

    notify("Could not start the package script: " .. script, vim.log.levels.ERROR)
    return false
  end

  vim.cmd("startinsert")

  return true
end

-- Resolve context, select an existing script, and run it in a terminal.
function M.run(bufnr, candidates)
  local context, context_err = M.resolve(bufnr)

  if not context then
    notify(context_err, vim.log.levels.ERROR)
    return false
  end

  local script, script_err = M.select_script(context, candidates)

  if not script then
    notify(script_err, vim.log.levels.WARN)
    return false
  end

  local executable, prefix = resolve_executable(context.package_manager)

  if not executable then
    notify(context.package_manager .. " is not available on PATH", vim.log.levels.ERROR)
    return false
  end

  local command = build_command(executable, prefix, context.package_manager, script)

  notify(string.format("Running %s with %s in %s", script, context.package_manager, context.package_root))

  return run_terminal(command, context.package_root, script)
end

return M
