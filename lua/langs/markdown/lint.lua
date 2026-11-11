-- On-demand Markdown linting through markdownlint-cli2.
--
-- Uses stdin so unsaved buffer content is linted.
-- Publishes structured results through vim.diagnostic.
-- Rejects stale results and handles invalid buffers safely.
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
  return vim.fs.root(bufnr, ".markdownlint-cli2.yaml") or vim.fn.getcwd()
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

local function build_diagnostics(bufnr, results)
  local diagnostics = {}
  local line_count = vim.api.nvim_buf_line_count(bufnr)

  if line_count == 0 then
    return diagnostics
  end

  for _, result in ipairs(results) do
    if type(result) == "table" then
      local line_number = optional_number(result.lineNumber, 1)

      if line_number >= 1 then
        local line = math.min(line_count - 1, math.floor(line_number - 1))

        local line_content = vim.api.nvim_buf_get_lines(bufnr, line, line + 1, false)[1] or ""

        local line_length = #line_content

        local column = optional_number(result.column, 1)
        local col = math.min(line_length, math.max(0, math.floor(column - 1)))

        local reported_length = optional_number(result.length, 1)
        local length = math.min(line_length - col, math.max(0, math.floor(reported_length)))

        local rule_names = type(result.ruleNames) == "table" and result.ruleNames or {}

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
  end

  return diagnostics
end

local function process_result(bufnr, request_id, changedtick, result)
  -- Ignore results for buffers that no longer exist.
  if not vim.api.nvim_buf_is_valid(bufnr) then
    if requests[bufnr] == request_id then
      requests[bufnr] = nil
    end

    return
  end

  -- Ignore results from superseded requests.
  if requests[bufnr] ~= request_id then
    return
  end

  -- Discard results if the buffer changed during linting.
  if vim.api.nvim_buf_get_changedtick(bufnr) ~= changedtick then
    requests[bufnr] = nil
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

  if not decode_ok or type(results) ~= "table" then
    notify("Could not decode markdownlint-cli2 JSON output:\n" .. stdout, vim.log.levels.ERROR)

    return
  end

  vim.diagnostic.set(namespace, bufnr, build_diagnostics(bufnr, results))
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

  local root = get_project_root(bufnr)
  local config = vim.fs.joinpath(root, ".markdownlint-cli2.yaml")

  command[#command + 1] = "--no-globs"

  if vim.fn.filereadable(config) == 1 then
    command[#command + 1] = "--config"
    command[#command + 1] = config
  end

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

  -- Register this request before starting the process.
  requests[bufnr] = request_id

  -- Remove diagnostics from the previous lint result.
  vim.diagnostic.reset(namespace, bufnr)

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
    -- Do not clear a newer request's state.
    if requests[bufnr] == request_id then
      requests[bufnr] = nil
    end

    notify("Could not start markdownlint-cli2: " .. tostring(process), vim.log.levels.ERROR)

    return
  end

  -- Return the process handle for testing and process inspection.
  return process
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
