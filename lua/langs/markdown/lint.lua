-- On-demand Markdown linting through markdownlint-cli2.
--
-- Uses stdin so unsaved buffer content is linted.
-- Publishes structured results through vim.diagnostic.
-- Rejects stale results and handles invalid buffers safely.
-- Uses HETFS configuration as the baseline for all projects.
-- Project configurations may override Markdown rules.
-- Validates project configuration before linting.
-- No automatic linting or dependency installation.

local M = {}

local namespace = vim.api.nvim_create_namespace("markdownlint-cli2")
local requests = {}
local next_request_id = 0
local configured = false

local function notify(message, level)
  vim.notify(message, level, {
    title = "MarkdownLint",
  })
end

local function resolve_command()
  local node = vim.fn.exepath("node")
  local cli = vim.fn.exepath("markdownlint-cli2")

  if node == "" then
    return nil, "Node.js was not found in Neovim's PATH."
  end

  if cli == "" then
    return nil, "markdownlint-cli2 was not found in Neovim's PATH."
  end

  local entrypoint = vim.fs.joinpath(vim.fs.dirname(cli), "node_modules", "markdownlint-cli2", "markdownlint-cli2-bin.mjs")

  if vim.fn.filereadable(entrypoint) ~= 1 then
    return nil, "Could not locate the markdownlint-cli2 Node entry point."
  end

  return {
    node,
    entrypoint,
  }
end

local function get_project_root(bufnr)
  local markers = {
    ".markdownlint-cli2.jsonc",
    ".markdownlint-cli2.yaml",
    ".markdownlint-cli2.cjs",
    ".markdownlint-cli2.mjs",
  }

  return vim.fs.root(bufnr, markers) or vim.fn.getcwd()
end

local function get_hetfs_config()
  local config_root = require("langs").root()

  local config = vim.fs.joinpath(config_root, ".markdownlint-cli2.yaml")

  if vim.fn.filereadable(config) ~= 1 then
    return nil, "HETFS markdownlint configuration was not found: " .. config
  end

  return config
end

local function get_validator_path()
  local config_root = require("langs").root()

  local validator = vim.fs.joinpath(config_root, "scripts", "markdownlint", "validate-config.mjs")

  if vim.fn.filereadable(validator) ~= 1 then
    return nil, "Markdown configuration validator was not found: " .. validator
  end

  return validator
end

local function optional_string(value)
  if type(value) == "string" then
    return value
  end

  return nil
end

local function optional_number(value, fallback)
  if type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge then
    return value
  end

  return fallback
end

local function is_finite_number(value)
  return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

-- Validate the structured output expected from the HETFS formatter.
local function validate_results(results)
  if type(results) ~= "table" then
    return false, "The formatter output must be a JSON array."
  end

  for index, result in ipairs(results) do
    if type(result) ~= "table" then
      return false, string.format("Diagnostic entry %d must be an object.", index)
    end

    if type(result.fileName) ~= "string" then
      return false, string.format("Diagnostic entry %d has an invalid fileName.", index)
    end

    if not is_finite_number(result.lineNumber) or result.lineNumber < 1 then
      return false, string.format("Diagnostic entry %d has an invalid lineNumber.", index)
    end

    if result.column ~= nil and result.column ~= vim.NIL and not is_finite_number(result.column) then
      return false, string.format("Diagnostic entry %d has an invalid column.", index)
    end

    if result.length ~= nil and result.length ~= vim.NIL and not is_finite_number(result.length) then
      return false, string.format("Diagnostic entry %d has an invalid length.", index)
    end

    if type(result.ruleNames) ~= "table" then
      return false, string.format("Diagnostic entry %d has invalid ruleNames.", index)
    end

    for _, rule_name in ipairs(result.ruleNames) do
      if type(rule_name) ~= "string" then
        return false, string.format("Diagnostic entry %d contains an invalid rule name.", index)
      end
    end

    for _, field in ipairs({
      "ruleDescription",
      "errorDetail",
      "errorContext",
    }) do
      local value = result[field]

      if value ~= nil and value ~= vim.NIL and type(value) ~= "string" then
        return false, string.format("Diagnostic entry %d has an invalid %s.", index, field)
      end
    end

    if
      result.severity ~= nil
      and result.severity ~= vim.NIL
      and not is_finite_number(result.severity)
      and result.severity ~= "warning"
      and result.severity ~= "error"
    then
      return false, string.format("Diagnostic entry %d has an invalid severity.", index)
    end
  end

  return true
end

local function build_diagnostics(bufnr, results)
  local diagnostics = {}
  local line_count = vim.api.nvim_buf_line_count(bufnr)

  if line_count == 0 then
    return diagnostics
  end

  for _, result in ipairs(results) do
    local line_number = optional_number(result.lineNumber, 1)

    if line_number >= 1 then
      local line = math.min(line_count - 1, math.floor(line_number - 1))

      local line_content = vim.api.nvim_buf_get_lines(bufnr, line, line + 1, false)[1] or ""

      local line_length = #line_content

      local column = optional_number(result.column, 1)
      local col = math.min(line_length, math.max(0, math.floor(column - 1)))

      local reported_length = optional_number(result.length, 1)
      local length = math.min(line_length - col, math.max(0, math.floor(reported_length)))

      local rule_names = result.ruleNames

      local message = optional_string(result.ruleDescription) or "Markdown lint issue"

      local detail = optional_string(result.errorDetail)
      local context = optional_string(result.errorContext)

      if detail then
        message = message .. ": " .. detail
      end

      if context then
        message = message .. "\nContext: " .. context
      end

      local severity = result.severity == "warning" and vim.diagnostic.severity.WARN or vim.diagnostic.severity.ERROR

      diagnostics[#diagnostics + 1] = {
        lnum = line,
        col = col,
        end_lnum = line,
        end_col = col + length,
        severity = severity,
        source = "markdownlint-cli2",
        code = optional_string(rule_names[1]),
        message = message,
      }
    end
  end

  return diagnostics
end

local function is_current_request(bufnr, request_id, changedtick)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    if requests[bufnr] == request_id then
      requests[bufnr] = nil
    end

    return false
  end

  if requests[bufnr] ~= request_id then
    return false
  end

  if vim.api.nvim_buf_get_changedtick(bufnr) ~= changedtick then
    requests[bufnr] = nil
    return false
  end

  return true
end

local function process_result(bufnr, request_id, changedtick, result)
  if not is_current_request(bufnr, request_id, changedtick) then
    return
  end

  -- This request is current and its buffer is unchanged.
  requests[bufnr] = nil

  local stdout = result.stdout or ""
  local stderr = result.stderr or ""

  -- Exit code 1 is valid: markdownlint uses it when
  -- lint errors are present.
  if result.code ~= 0 and result.code ~= 1 then
    local message = stderr ~= "" and stderr or stdout

    notify("markdownlint-cli2 failed:\n" .. message, vim.log.levels.ERROR)

    return
  end

  local decode_ok, results = pcall(vim.json.decode, stdout)

  if not decode_ok then
    notify("Could not decode markdownlint-cli2 JSON output:\n" .. stdout, vim.log.levels.ERROR)

    return
  end

  local valid, validation_error = validate_results(results)

  if not valid then
    notify("markdownlint-cli2 output violates the HETFS JSON diagnostic contract:\n" .. validation_error, vim.log.levels.ERROR)

    return
  end

  vim.diagnostic.set(namespace, bufnr, build_diagnostics(bufnr, results))
end

local function validate_project_config(node, validator, entrypoint, root, callback)
  local command = {
    node,
    validator,
    entrypoint,
    root,
  }

  local ok, process = pcall(vim.system, command, {
    cwd = root,
    text = true,
  }, function(result)
    vim.schedule(function()
      callback(result)
    end)
  end)

  if not ok then
    return nil, "Could not start Markdown configuration validation: " .. tostring(process)
  end

  return process
end

local function start_lint(command, root, content, bufnr, request_id, changedtick)
  local ok, process = pcall(vim.system, command, {
    cwd = root,
    stdin = content,
    text = true,
  }, function(result)
    vim.schedule(function()
      process_result(bufnr, request_id, changedtick, result)
    end)
  end)

  if not ok then
    if requests[bufnr] == request_id then
      requests[bufnr] = nil
    end

    notify("Could not start markdownlint-cli2: " .. tostring(process), vim.log.levels.ERROR)

    return nil
  end

  return process
end

local function handle_validation_result(bufnr, request_id, changedtick, result, start_lint_callback)
  if not is_current_request(bufnr, request_id, changedtick) then
    return
  end

  local stdout = result.stdout or ""
  local stderr = result.stderr or ""

  local decode_ok, validation = pcall(vim.json.decode, stdout)

  if not decode_ok or type(validation) ~= "table" then
    requests[bufnr] = nil

    local detail = stderr ~= "" and stderr or stdout

    notify("Could not decode Markdown configuration validation output:\n" .. detail, vim.log.levels.ERROR)

    return
  end

  if result.code ~= 0 or validation.valid ~= true then
    requests[bufnr] = nil

    local errors = {}

    if type(validation.errors) == "table" then
      for _, message in ipairs(validation.errors) do
        if type(message) == "string" then
          errors[#errors + 1] = message
        end
      end
    end

    local message

    if #errors > 0 then
      message = table.concat(errors, "\n")
    else
      message = validation.message or "Markdown configuration validation failed."
    end

    notify(message, vim.log.levels.ERROR)

    return
  end

  start_lint_callback()
end

function M.clear(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  -- Invalidate any outstanding request.
  requests[bufnr] = nil

  -- Remove diagnostics from this integration.
  vim.diagnostic.reset(namespace, bufnr)
end

function M.lint(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  if not vim.api.nvim_buf_is_valid(bufnr) or not vim.api.nvim_buf_is_loaded(bufnr) then
    notify("The current buffer is not available.", vim.log.levels.WARN)
    return
  end

  if vim.bo[bufnr].filetype ~= "markdown" then
    notify("The current buffer is not Markdown.", vim.log.levels.WARN)
    return
  end

  local command, command_error = resolve_command()

  if not command then
    notify(command_error, vim.log.levels.ERROR)
    return
  end

  local config, config_error = get_hetfs_config()

  if not config then
    notify(config_error, vim.log.levels.ERROR)
    return
  end

  local validator, validator_error = get_validator_path()

  if not validator then
    notify(validator_error, vim.log.levels.ERROR)
    return
  end

  local root = get_project_root(bufnr)

  local node = command[1]
  local entrypoint = command[2]

  -- Always load the HETFS baseline configuration.
  -- Project-level rule overrides remain discoverable
  -- through the process working directory.
  command[#command + 1] = "--no-globs"
  command[#command + 1] = "--config"
  command[#command + 1] = config
  command[#command + 1] = "-"

  -- Capture the current buffer content, including unsaved changes.
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local content = table.concat(lines, "\n")

  if vim.bo[bufnr].endofline then
    content = content .. "\n"
  end

  next_request_id = next_request_id + 1

  local request_id = next_request_id
  local changedtick = vim.api.nvim_buf_get_changedtick(bufnr)

  -- Register this request before starting validation.
  requests[bufnr] = request_id

  -- Remove diagnostics from the previous lint result.
  vim.diagnostic.reset(namespace, bufnr)

  local function run_lint()
    if not is_current_request(bufnr, request_id, changedtick) then
      return
    end

    start_lint(command, root, content, bufnr, request_id, changedtick)
  end

  local validation_process, start_error = validate_project_config(node, validator, entrypoint, root, function(result)
    handle_validation_result(bufnr, request_id, changedtick, result, run_lint)
  end)

  if not validation_process then
    if requests[bufnr] == request_id then
      requests[bufnr] = nil
    end

    notify(start_error, vim.log.levels.ERROR)

    return
  end

  -- Return the validation process handle.
  -- The markdownlint process starts after validation succeeds.
  return validation_process
end

function M.setup()
  if configured then
    return
  end

  local group = vim.api.nvim_create_augroup("MarkdownLint", {
    clear = true,
  })

  vim.api.nvim_create_autocmd("BufWipeout", {
    group = group,
    desc = "Clean up Markdown lint requests",
    callback = function(event)
      requests[event.buf] = nil
    end,
  })

  vim.api.nvim_create_user_command("MarkdownLint", function()
    M.lint()
  end, {
    desc = "Lint current Markdown buffer",
    force = true,
  })

  configured = true
end

return M
