-- SQLFluff static analysis for the SQL language pack.
--
-- SQLFluff owns static analysis only.
-- Formatting remains owned by sql-formatter through Conform.

local M = {}

local namespace = vim.api.nvim_create_namespace("sqlfluff")

local RULES = {
  "RF02",
  "AM05",
}

local DIALECTS = {
  postgresql = "postgres",
  mysql = "mysql",
  sqlite = "sqlite",
}

local DEBOUNCE_MS = 500

local request_ids = {}
local processes = {}
local attached = {}
local debounce_ids = {}

local warned_missing = false
local setup_done = false

-- ============================================================
-- Notifications and Buffer State
-- ============================================================

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.WARN, {
    title = "SQLFluff",
  })
end

local function valid_buffer(bufnr)
  return vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_is_loaded(bufnr)
end

local function next_request(bufnr)
  request_ids[bufnr] = (request_ids[bufnr] or 0) + 1

  return request_ids[bufnr]
end

local function stop_process(bufnr)
  local process = processes[bufnr]
  processes[bufnr] = nil

  if process then
    pcall(process.kill, process, 15)
  end
end

local function next_debounce(bufnr)
  debounce_ids[bufnr] = (debounce_ids[bufnr] or 0) + 1

  return debounce_ids[bufnr]
end

-- ============================================================
-- Cleanup and Scheduling
-- ============================================================

---Invalidate requests, stop the process, and optionally clear diagnostics.
---@param bufnr integer
---@param clear_diagnostics? boolean
local function cleanup(bufnr, clear_diagnostics)
  next_request(bufnr)
  next_debounce(bufnr)
  stop_process(bufnr)

  if clear_diagnostics and valid_buffer(bufnr) then
    vim.diagnostic.reset(namespace, bufnr)
  end
end

---Schedule a debounced SQLFluff lint request.
---@param bufnr integer
local function schedule_lint(bufnr)
  local debounce_id = next_debounce(bufnr)

  vim.defer_fn(function()
    if debounce_ids[bufnr] ~= debounce_id then
      return
    end

    if not valid_buffer(bufnr) then
      return
    end

    if vim.bo[bufnr].filetype ~= "sql" then
      return
    end

    M.lint(bufnr)
  end, DEBOUNCE_MS)
end

-- ============================================================
-- Buffer Lifecycle
-- ============================================================

local function attach_buffer(bufnr)
  if attached[bufnr] then
    return true
  end

  local ok = vim.api.nvim_buf_attach(bufnr, false, {
    on_lines = function(_, changed_buf)
      vim.schedule(function()
        if valid_buffer(changed_buf) then
          cleanup(changed_buf, true)
          schedule_lint(changed_buf)
        end
      end)
    end,

    on_detach = function(_, detached_buf)
      vim.schedule(function()
        cleanup(detached_buf, true)

        attached[detached_buf] = nil
        request_ids[detached_buf] = nil
        debounce_ids[detached_buf] = nil
      end)
    end,
  })

  if ok then
    attached[bufnr] = true
  end

  return ok
end

-- ============================================================
-- Public Diagnostic API
-- ============================================================

---Clear diagnostics and invalidate any outstanding request.
---@param bufnr integer
function M.clear(bufnr)
  cleanup(bufnr, true)
end

-- ============================================================
-- SQLFluff Execution
-- ============================================================

---Run SQLFluff against a SQL buffer.
---@param bufnr? integer
---@return table? process
function M.lint(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  if not valid_buffer(bufnr) then
    return nil
  end

  next_debounce(bufnr)

  local request_id = next_request(bufnr)

  stop_process(bufnr)

  if vim.bo[bufnr].filetype ~= "sql" then
    return nil
  end

  if not attach_buffer(bufnr) then
    notify("Unable to attach SQLFluff lifecycle callbacks to the buffer.")

    return nil
  end

  if vim.fn.executable("sqlfluff") ~= 1 then
    if not warned_missing then
      warned_missing = true
      notify("Executable 'sqlfluff' was not found in PATH.")
    end

    return nil
  end

  local dialect = require("langs.sql").resolve_dialect(bufnr)
  local sqlfluff_dialect = DIALECTS[dialect]

  if not sqlfluff_dialect then
    notify(("Unsupported SQL dialect: %s"):format(dialect))

    return nil
  end

  local filename = vim.api.nvim_buf_get_name(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local content = table.concat(lines, "\n")
  local changedtick = vim.api.nvim_buf_get_changedtick(bufnr)

  local args = {
    "sqlfluff",
    "lint",
    "--dialect",
    sqlfluff_dialect,
    "--rules",
    table.concat(RULES, ","),
    "--format",
    "json",
  }

  if filename ~= "" then
    vim.list_extend(args, {
      "--stdin-filename",
      filename,
    })
  end

  table.insert(args, "-")

  local ok, process_or_error = pcall(vim.system, args, {
    stdin = content,
    text = true,
  }, function(result)
    vim.schedule(function()
      if request_ids[bufnr] ~= request_id then
        return
      end

      processes[bufnr] = nil

      if not valid_buffer(bufnr) then
        return
      end

      if vim.api.nvim_buf_get_changedtick(bufnr) ~= changedtick then
        return
      end

      if result.code ~= 0 and result.code ~= 1 then
        notify(("Execution failed (exit code %s): %s"):format(result.code, result.stderr or ""))

        return
      end

      local decoded_ok, decoded = pcall(vim.json.decode, result.stdout or "")

      if not decoded_ok or type(decoded) ~= "table" or type(decoded[1]) ~= "table" or type(decoded[1].violations) ~= "table" then
        notify("SQLFluff returned invalid JSON output.")

        return
      end

      local diagnostics = {}

      for _, violation in ipairs(decoded[1].violations) do
        diagnostics[#diagnostics + 1] = {
          lnum = violation.start_line_no - 1,
          col = violation.start_line_pos - 1,
          end_lnum = violation.end_line_no - 1,
          end_col = violation.end_line_pos - 1,
          message = violation.description,
          severity = vim.diagnostic.severity.WARN,
          source = "sqlfluff",
          code = violation.code,
        }
      end

      vim.diagnostic.set(namespace, bufnr, diagnostics)
    end)
  end)

  if not ok then
    notify(("Unable to start SQLFluff: %s"):format(process_or_error))

    return nil
  end

  processes[bufnr] = process_or_error

  return process_or_error
end

-- ============================================================
-- Automatic Lint Setup
-- ============================================================

---Set up automatic SQLFluff linting.
function M.setup()
  if setup_done then
    return
  end

  setup_done = true

  local group = vim.api.nvim_create_augroup("SQLFluff", {
    clear = true,
  })

  vim.api.nvim_create_autocmd("BufEnter", {
    group = group,
    callback = function(event)
      if valid_buffer(event.buf) and vim.bo[event.buf].filetype == "sql" then
        M.lint(event.buf)
      end
    end,
  })

  local bufnr = vim.api.nvim_get_current_buf()

  if valid_buffer(bufnr) and vim.bo[bufnr].filetype == "sql" then
    M.lint(bufnr)
  end
end

return M
